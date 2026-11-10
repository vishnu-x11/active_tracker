import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../../profile/profile_api.dart';
import '../../data/data_sources/location_source.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/run_settings.dart';
import '../../domain/use_cases/motion_detector.dart';
import '../../domain/use_cases/voice_cues.dart';
import '../providers.dart';
import '../states/run_recorder_state.dart';

final runRecorderProvider = NotifierProvider.autoDispose<RunRecorderNotifier, RunRecorderState>(
  RunRecorderNotifier.new,
);

class RunRecorderNotifier extends Notifier<RunRecorderState> {
  static const maxAccuracyM = 25.0;
  static const lostMs = 10000;

  StreamSubscription<GpsFix>? _gps;
  Timer? _ticker;
  Timer? _retry;
  int? _lastGoodFixMs;
  int _lastSaveMs = 0;
  Future<void> _saves = Future.value();

  DateTime? _since;
  int _before = 0;

  final _motion = MotionDetector();
  SplitCues? _splits;
  WorkoutCoach? _coach;

  int _nowMs() => ref.read(recorderClockProvider)().millisecondsSinceEpoch;

  @override
  RunRecorderState build() {
    ref.listen(profileProvider, (_, _) {});
    ref.onDispose(() {
      _gps?.cancel();
      _ticker?.cancel();
      _retry?.cancel();
    });
    Future.microtask(() async {
      final p = await ref.read(profileProvider.future);
      if (ref.mounted && p != null) state = state.copyWith(weightKg: p.weightKg);
    });
    Future.microtask(() async {
      await _loadSettings();
      await _restore();
      await _prepare();
    });
    return const RunRecorderState();
  }

  Future<void> _restore() async {
    final result = await ref.read(getUnfinishedRecordingProvider)(now: ref.read(recorderClockProvider)());
    if (!ref.mounted || state.status != RecorderStatus.ready) return;
    if (result case Ok(value: final r?)) {
      _before = r.movingMs;
      _splits = SplitCues(state.settings.splitEveryM, fromM: r.meters);
      _coach = WorkoutCoach(state.settings.workout);
      state = state.copyWith(
        status: RecorderStatus.paused,
        points: r.points,
        segment: r.segment,
        elapsedMs: r.movingMs,
        here: r.points.lastOrNull,
        restored: true,
      );
      _progress();
    }
  }

  void _persist({bool force = false}) {
    if (state.status == RecorderStatus.ready || state.saving) return;
    final now = _nowMs();
    if (!force && now - _lastSaveMs < 5000) return;
    _lastSaveMs = now;
    final snapshot = Recording(
      points: state.points,
      segment: state.segment,
      movingMs: state.status.stopped ? _before : _moving(),
      savedAt: ref.read(recorderClockProvider)(),
    );
    final save = ref.read(saveRecordingProgressProvider);
    _saves = _saves.then((_) => save(snapshot));
  }

  Future<void> _forget() {
    final clear = ref.read(clearRecordingProvider);
    return _saves = _saves.then((_) => clear());
  }

  Future<void> discard() async {
    _ticker?.cancel();
    _retry?.cancel();
    final gps = _gps;
    _gps = null;
    await gps?.cancel();
    await _forget();
  }

  Future<void> _loadSettings() async {
    final result = await ref.read(getRunSettingsProvider)();
    if (!ref.mounted || state.status != RecorderStatus.ready) return;
    if (result case Ok(:final value)) {
      state = state.copyWith(settings: value, coach: () => WorkoutCoach(value.workout).view(meters: 0, seconds: 0));
    }
  }

  Future<void> _prepare() async {
    final source = ref.read(locationSourceProvider);
    final problem = await source.ensureAccess();
    if (!ref.mounted) return;
    if (problem != null) {
      state = state.copyWith(problem: () => problem);
      return;
    }
    if (_gps == null) await _listen(background: state.status != RecorderStatus.ready);
    if (!ref.mounted) return;
    final here = await source.current();
    if (ref.mounted && here != null && state.here == null) state = state.copyWith(here: here);
  }

  void updateSettings(RunSettings next) {
    final s = state.status == RecorderStatus.ready ? next : next.copyWith(workout: state.settings.workout);
    final splitChanged = s.splitEveryM != state.settings.splitEveryM;
    state = state.copyWith(
      settings: s,
      coach: state.status == RecorderStatus.ready ? () => WorkoutCoach(s.workout).view(meters: 0, seconds: 0) : null,
    );
    if (splitChanged && state.status != RecorderStatus.ready) _splits = SplitCues(s.splitEveryM, fromM: state.meters);
    if (!s.voice) ref.read(speakerProvider).stop();
    if (!s.autoPauseActive && state.status == RecorderStatus.autoPaused) resume();
    ref.read(saveRunSettingsProvider)(s);
  }

  void _say(String text) {
    if (state.settings.voice) ref.read(speakerProvider).say(text);
  }

  Future<void> start() async {
    if (state.status != RecorderStatus.ready) return;
    final problem = await ref.read(locationSourceProvider).ensureAccess();
    if (!ref.mounted) return;
    if (problem != null) {
      state = state.copyWith(problem: () => problem);
      return;
    }
    await _listen(background: true);
    if (!ref.mounted) return;
    state = state.copyWith(status: RecorderStatus.recording, problem: () => null);
    _motion.reset(_nowMs(), state.here);
    _splits = SplitCues(state.settings.splitEveryM);
    _coach = WorkoutCoach(state.settings.workout);
    _resumeClock();
    _say('Run started.');
    _progress();
    _persist(force: true);
  }

  Future<void> _listen({bool background = false}) async {
    _retry?.cancel();
    final old = _gps;
    _gps = null;
    await old?.cancel();
    if (!ref.mounted) return;
    late final StreamSubscription<GpsFix> sub;
    sub = ref
        .read(locationSourceProvider)
        .fixes(background: background)
        .listen(
          _onFix,
          onError: (Object _) {
            if (ref.mounted && state.signal == GpsSignal.good) state = state.copyWith(signal: GpsSignal.weak);
          },
          onDone: () {
            if (!ref.mounted || _gps != sub) return;
            _gps = null;
            _retry = Timer(const Duration(seconds: 2), () {
              if (ref.mounted && _gps == null) _listen(background: state.status != RecorderStatus.ready);
            });
          },
        );
    _gps = sub;
  }

  void _onFix(GpsFix fix) {
    final now = _nowMs();
    final p = fix.point;
    final good = fix.accuracy <= maxAccuracyM;
    if (good) _lastGoodFixMs = now;
    state = state.copyWith(here: p, signal: good ? GpsSignal.good : GpsSignal.weak);
    if (!good) return;
    switch (state.status) {
      case RecorderStatus.recording:
        _motion.onFix(p, now, speed: fix.speed);
        state = state.copyWith(points: [...state.points, p.withSegment(state.segment)]);
        _progress();
      case RecorderStatus.autoPaused when _motion.onFix(p, now, speed: fix.speed):
        _resume(announce: 'Resumed.');
        state = state.copyWith(points: [...state.points, p.withSegment(state.segment)]);
        _motion.reset(now, p);
      case _:
    }
  }

  void _tick() {
    final lost = _lastGoodFixMs == null || _nowMs() - _lastGoodFixMs! > lostMs;
    state = state.copyWith(
      elapsedMs: _moving(),
      signal: lost && state.signal == GpsSignal.good ? GpsSignal.weak : null,
    );
    if (state.settings.autoPauseActive && _motion.isStill(_nowMs())) {
      _autoPause();
    } else {
      _progress();
    }
    _persist();
  }

  void _progress() {
    final meters = state.meters;
    final secs = state.elapsedMs ~/ 1000;
    final pace = state.currentPace;
    if (_splits?.check(meters: meters, seconds: secs) case final split?) _say(split);
    for (final line in _coach?.update(meters: meters, seconds: secs, pace: pace) ?? const <String>[]) {
      _say(line);
    }
    final view = _coach?.view(meters: meters, seconds: secs, pace: pace);
    if (view != state.coach) state = state.copyWith(coach: () => view);
  }

  void _stopClock() {
    _before = _moving();
    _since = null;
    _ticker?.cancel();
  }

  void _autoPause() {
    final still = _nowMs() - (_motion.lastMoveMs ?? _nowMs());
    final moving = _moving();
    _stopClock();
    _before = math.max(moving - still, 0);
    state = state.copyWith(status: RecorderStatus.autoPaused, elapsedMs: _before);
    _say('Auto-paused.');
    _persist(force: true);
  }

  void pause() {
    if (state.status == RecorderStatus.autoPaused) {
      state = state.copyWith(status: RecorderStatus.paused);
      return;
    }
    if (state.status != RecorderStatus.recording) return;
    _stopClock();
    state = state.copyWith(status: RecorderStatus.paused, elapsedMs: _before);
    _say('Paused.');
    _persist(force: true);
  }

  void resume() {
    if (!state.status.stopped) return;
    _resume(announce: 'Resumed.');
    _motion.reset(_nowMs(), state.here);
  }

  void _resume({required String announce}) {
    state = state.copyWith(status: RecorderStatus.recording, segment: state.segment + 1, restored: false);
    _resumeClock();
    _say(announce);
    _persist(force: true);
  }

  void _resumeClock() {
    _since = ref.read(recorderClockProvider)();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  int _moving() =>
      _before + (_since == null ? 0 : ref.read(recorderClockProvider)().difference(_since!).inMilliseconds);

  Future<void> finish() async {
    if (state.status == RecorderStatus.ready || state.saving) return;
    if (state.status == RecorderStatus.recording) {
      _stopClock();
      state = state.copyWith(status: RecorderStatus.paused, elapsedMs: _before);
    }
    _retry?.cancel();
    final gps = _gps;
    _gps = null;
    await gps?.cancel();
    state = state.copyWith(saving: true, error: () => null);
    final hour = DateTime.now().hour;
    final title = hour < 11 ? 'Morning Run' : (hour < 14 ? 'Lunch Run' : (hour < 19 ? 'Evening Run' : 'Night Run'));
    final result = await ref.read(saveRunDraftProvider)(points: state.points, weightKg: state.weightKg, title: title);
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        await _forget();
        if (!ref.mounted) return;
        _say('Run finished. ${Speech.distance(state.meters)} in ${Speech.duration(state.elapsedMs ~/ 1000)}.');
        state = state.copyWith(saving: false, draftId: value);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
        unawaited(_listen(background: true));
    }
  }

  Future<void> openSettings() => ref.read(locationSourceProvider).openSettings();
}
