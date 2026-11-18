import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;

import '../../../../core/result.dart';
import '../../../../core/sync/sync_controller.dart';
import '../../../profile/profile_api.dart';
import '../../data/data_sources/location_source.dart';
import '../../domain/entities/recording.dart';
import '../../domain/entities/run_settings.dart';
import '../../domain/entities/track_point.dart';
import '../../domain/use_cases/gps_filter.dart';
import '../../domain/use_cases/motion_detector.dart';
import '../../domain/use_cases/step_distance.dart';
import '../../domain/use_cases/track_math.dart';
import '../../domain/use_cases/voice_cues.dart';
import '../providers.dart';
import '../states/run_recorder_state.dart';

final runRecorderProvider = NotifierProvider.autoDispose<RunRecorderNotifier, RunRecorderState>(
  RunRecorderNotifier.new,
);

class RunRecorderNotifier extends Notifier<RunRecorderState> {
  static const maxAccuracyM = 25.0;
  static const hereAccuracyM = 50.0;
  static const lostMs = 10000;
  static const speedSmoothing = 0.3;
  static const restartAfterMs = 15000;
  static const disconnectedAfterMs = 15000;
  static const minLearnSteps = 30;

  static const lostWithSteps = 'GPS disconnected. Using your steps to estimate distance.';
  static const lostNoSteps = 'GPS disconnected.';
  static const backAgain = 'GPS reconnected.';

  StreamSubscription<GpsFix>? _gps;
  StreamSubscription<bool>? _service;
  StreamSubscription<int>? _stepSub;
  Timer? _watch;
  int? _lastFixMs;
  int _streamAtMs = 0;
  int? _recordingAtMs;
  bool _rawGps = false;
  bool _recovering = false;
  bool _visible = true;
  int? _streamFixMs;
  Timer? _poll;
  bool _polling = false;
  bool _pollRaw = true;
  bool _serviceOff = false;
  bool _stepsOk = false;
  int? _steps;
  int? _stepsAtGood;
  int? _learnSteps;
  double _learnM = 0;
  double _extraM = 0;
  double _gapBaseM = 0;
  final _stride = StrideModel();
  final _cadence = StepCadence();
  final _gap = GapDistance();
  Timer? _ticker;
  Timer? _retry;
  int? _lastGoodFixMs;
  int _lastSaveMs = 0;
  Future<void> _saves = Future.value();
  KeepAliveLink? _alive;

  DateTime? _since;
  int _before = 0;

  final _motion = MotionDetector();
  final _filter = GpsFilter(maxAccuracyM: maxAccuracyM);
  SplitCues? _splits;
  WorkoutCoach? _coach;

  int _nowMs() => ref.read(recorderClockProvider)().millisecondsSinceEpoch;

  @override
  RunRecorderState build() {
    ref.listen(profileProvider, (_, _) {});
    ref.listen(dataRevisionProvider, (_, _) => unawaited(_loadSettings()));
    final life = AppLifecycleListener(
      onResume: _onResume,
      onShow: () => _visible = true,
      onHide: () {
        _visible = false;
        _persist(force: true);
      },
    );
    ref.onDispose(() {
      life.dispose();
      _gps?.cancel();
      _ticker?.cancel();
      _retry?.cancel();
      _stopWatching();
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

  void _hold() => _alive ??= ref.keepAlive();

  void _release() {
    _alive?.close();
    _alive = null;
  }

  void _onResume() {
    _visible = true;
    if (!ref.mounted || state.status == RecorderStatus.ready) return;
    if (state.status == RecorderStatus.recording) _tick();
    final quiet = _nowMs() - math.max(_streamFixMs ?? _streamAtMs, _streamAtMs);
    if (_gps == null || quiet > 5000) unawaited(_recover());
  }

  Future<void> _restore() async {
    final result = await ref.read(getUnfinishedRecordingProvider)(now: ref.read(recorderClockProvider)());
    if (!ref.mounted || state.status != RecorderStatus.ready) return;
    if (result case Ok(value: final r?)) {
      _before = r.movingMs;
      _extraM = r.extraM;
      _splits = SplitCues(state.settings.splitEveryM, fromM: r.meters);
      _coach = WorkoutCoach(state.settings.workout);
      _filter.reset();
      _hold();
      state = state.copyWith(
        status: RecorderStatus.paused,
        points: r.points,
        segment: r.segment,
        elapsedMs: r.movingMs,
        meters: r.meters,
        here: r.points.lastOrNull,
        restored: true,
      );
      _progress();
      unawaited(_startWatching(askSteps: false));
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
      extraM: _extraM + (_gap.open ? _gap.meters(_stride.strideM) : 0),
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
    _stopWatching();
    final gps = _gps;
    _gps = null;
    await gps?.cancel();
    await _forget();
    _release();
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
    unawaited(ref.read(saveRunSettingsProvider)(s).then((_) => ref.read(syncControllerProvider.notifier).nudge()));
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
    _hold();
    _recordingAtMs = _nowMs();
    state = state.copyWith(status: RecorderStatus.recording, problem: () => null);
    unawaited(_startWatching(askSteps: true));
    _motion.reset(_nowMs(), state.here);
    _filter.reset();
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
    await old?.cancel().timeout(const Duration(seconds: 3), onTimeout: () {});
    if (!ref.mounted) return;
    _streamAtMs = _nowMs();
    late final StreamSubscription<GpsFix> sub;
    sub = ref
        .read(locationSourceProvider)
        .fixes(background: background, rawGps: _rawGps)
        .listen(
          (fix) {
            _streamFixMs = _nowMs();
            _stopPolling();
            _onFix(fix);
          },
          onError: (Object _) {
            if (!ref.mounted || _gps != sub) return;
            if (state.signal == GpsSignal.good) state = state.copyWith(signal: GpsSignal.weak);
            _retry?.cancel();
            _retry = Timer(const Duration(seconds: 2), () => unawaited(_recover()));
          },
          onDone: () {
            if (!ref.mounted || _gps != sub) return;
            _gps = null;
            _retry = Timer(const Duration(seconds: 2), () {
              if (!ref.mounted || _gps != null) return;
              if (state.status == RecorderStatus.ready) {
                unawaited(_listen());
              } else {
                unawaited(_recover());
              }
            });
          },
        );
    _gps = sub;
  }

  void _onFix(GpsFix fix) {
    final now = _nowMs();
    final raw = fix.point;
    final good = fix.accuracy <= maxAccuracyM;
    _lastFixMs = now;
    if (good) {
      _lastGoodFixMs = now;
      _stepsAtGood = _steps;
    }
    if (good && state.signal == GpsSignal.lost) _alert(backAgain);
    state = state.copyWith(
      here: good || state.here == null || fix.accuracy <= hereAccuracyM ? raw : null,
      signal: good ? GpsSignal.good : GpsSignal.weak,
    );
    if (!good) return;
    switch (state.status) {
      case RecorderStatus.recording:
        final f = _filter.accept(fix);
        if (f == null) return;
        _motion.onFix(f.point, now, speed: fix.speed);
        final prev = state.speedMps;
        state = state.copyWith(speedMps: () => prev == null ? fix.speed : prev + speedSmoothing * (fix.speed - prev));
        if (f.keep) _append(f.point);
        _progress();
      case RecorderStatus.autoPaused:
        final f = _filter.accept(fix);
        if (f == null || !_motion.onFix(f.point, now, speed: fix.speed)) return;
        _resume(announce: 'Resumed.');
        _filter
          ..cut()
          ..mark(f.point);
        _append(f.point);
        _motion.reset(now, f.point);
      case _:
    }
  }

  void _append(TrackPoint p) {
    final pts = state.points;
    final q = p.withSegment(state.segment);
    final straight = pts.isNotEmpty && pts.last.segment == q.segment
        ? TrackMath.meters(pts.last.lat, pts.last.lng, q.lat, q.lng)
        : 0.0;
    var m = state.meters + straight;
    if (_gap.open) {
      final extra = GapDistance.bridge(stepMeters: _gap.meters(_stride.strideM), straightMeters: straight);
      _extraM += extra;
      m = _gapBaseM + straight + extra;
      _gap.close();
      _learnSteps = null;
    }
    state = state.copyWith(points: [...pts, q], meters: m, onSteps: false);
  }

  void _tick() {
    final now = _nowMs();
    final lost = _lastGoodFixMs == null || now - _lastGoodFixMs! > lostMs;
    final disconnected = state.signal == GpsSignal.lost;
    final stepSpeed = disconnected ? _stepSpeed(now) : null;
    state = state.copyWith(
      elapsedMs: _moving(),
      signal: lost && state.signal == GpsSignal.good ? GpsSignal.weak : null,
      speedMps: disconnected ? () => stepSpeed : (lost ? () => null : null),
    );
    _learnStride();
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
    _closeGap();
    final still = _nowMs() - (_motion.lastMoveMs ?? _nowMs());
    final moving = _moving();
    _stopClock();
    _before = math.max(moving - still, 0);
    state = state.copyWith(status: RecorderStatus.autoPaused, elapsedMs: _before, speedMps: () => null);
    _say('Auto-paused.');
    _persist(force: true);
  }

  void pause() {
    if (state.status == RecorderStatus.autoPaused) {
      state = state.copyWith(status: RecorderStatus.paused);
      return;
    }
    if (state.status != RecorderStatus.recording) return;
    _closeGap();
    _stopClock();
    state = state.copyWith(status: RecorderStatus.paused, elapsedMs: _before, speedMps: () => null);
    _say('Paused.');
    _persist(force: true);
  }

  void resume() {
    if (!state.status.stopped) return;
    _resume(announce: 'Resumed.');
    _filter.cut();
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
      _closeGap();
      _stopClock();
      state = state.copyWith(status: RecorderStatus.paused, elapsedMs: _before, speedMps: () => null);
    }
    _retry?.cancel();
    _stopWatching();
    final gps = _gps;
    _gps = null;
    await gps?.cancel();
    state = state.copyWith(saving: true, error: () => null);
    final hour = DateTime.now().hour;
    final title = hour < 11 ? 'Morning Run' : (hour < 14 ? 'Lunch Run' : (hour < 19 ? 'Evening Run' : 'Night Run'));
    final result = await ref.read(saveRunDraftProvider)(
      points: state.points,
      weightKg: state.weightKg,
      title: title,
      extraMeters: _extraM,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        await _forget();
        if (!ref.mounted) return;
        _say('Run finished. ${Speech.distance(state.meters)} in ${Speech.duration(state.elapsedMs ~/ 1000)}.');
        _release();
        state = state.copyWith(saving: false, draftId: value);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
        unawaited(_listen(background: true));
        unawaited(_startWatching(askSteps: false));
    }
  }

  Future<void> openSettings() => ref.read(locationSourceProvider).openSettings();

  Future<void> _startWatching({required bool askSteps}) async {
    _watch?.cancel();
    _watch = Timer.periodic(const Duration(seconds: 1), (_) => _watchTick());
    final source = ref.read(locationSourceProvider);
    _serviceOff = !await source.serviceOn();
    if (!ref.mounted) return;
    await _service?.cancel();
    _service = source.serviceEnabled().listen(_onService, onError: (Object _) {});
    final steps = ref.read(stepSourceProvider);
    _stepsOk = askSteps ? await steps.ensureAccess() : _stepsOk;
    if (!ref.mounted || !_stepsOk) return;
    await _stepSub?.cancel();
    _stepSub = steps.steps().listen(_onSteps, onError: (Object _) => _stepsOk = false);
  }

  void _startPolling() {
    _poll ??= Timer.periodic(const Duration(seconds: 3), (_) => unawaited(_pollOnce()));
    unawaited(_pollOnce());
  }

  void _stopPolling() {
    _poll?.cancel();
    _poll = null;
  }

  Future<void> _pollOnce() async {
    if (_polling || !ref.mounted || _serviceOff || state.status == RecorderStatus.ready) return;
    _polling = true;
    try {
      final fix = await ref.read(locationSourceProvider).poll(rawGps: _pollRaw);
      if (!ref.mounted || _poll == null) return;
      if (fix == null) {
        _pollRaw = !_pollRaw;
      } else {
        _onFix(fix);
      }
    } finally {
      _polling = false;
    }
  }

  void _stopWatching() {
    _stopPolling();
    _watch?.cancel();
    _watch = null;
    unawaited(_service?.cancel());
    _service = null;
    unawaited(_stepSub?.cancel());
    _stepSub = null;
  }

  void _watchTick() {
    if (!ref.mounted || state.status == RecorderStatus.ready || state.saving) return;
    final now = _nowMs();
    final quietSince = math.max(_streamFixMs ?? _streamAtMs, _streamAtMs);
    if (!_serviceOff && now - quietSince >= restartAfterMs) unawaited(_recover(switchProvider: true));
    if (state.status != RecorderStatus.recording) return;
    final since = _lastGoodFixMs == null ? (_recordingAtMs ?? now) : math.max(_lastGoodFixMs!, _recordingAtMs ?? 0);
    final gone = _serviceOff || now - since >= disconnectedAfterMs;
    if (gone && state.signal != GpsSignal.lost) {
      state = state.copyWith(signal: GpsSignal.lost, speedMps: () => null);
      _alert(_stepsOk ? lostWithSteps : lostNoSteps);
    }
    if (state.signal == GpsSignal.lost && !_gap.open) {
      _gap.begin(_stepsAtGood ?? _steps);
      _gapBaseM = state.meters;
      _learnSteps = null;
      state = state.copyWith(onSteps: _stepsOk);
    }
  }

  Future<void> _recover({bool switchProvider = false}) async {
    if (_recovering || !ref.mounted || state.status == RecorderStatus.ready || state.saving) return;
    _recovering = true;
    _streamAtMs = _nowMs();
    try {
      final source = ref.read(locationSourceProvider);
      _serviceOff = !await source.serviceOn();
      if (!ref.mounted) return;
      if (_serviceOff) {
        if (state.status == RecorderStatus.recording) _watchTick();
        return;
      }
      if (!_visible) {
        _startPolling();
        return;
      }
      if (switchProvider || _lastFixMs == null || _nowMs() - _lastFixMs! > 5000) _rawGps = !_rawGps;
      await _listen(background: true);
    } finally {
      _recovering = false;
    }
  }

  void _onService(bool on) {
    if (!ref.mounted) return;
    _serviceOff = !on;
    if (on) {
      unawaited(_recover());
    } else if (state.status == RecorderStatus.recording) {
      _watchTick();
    }
  }

  void _onSteps(int total) {
    if (!ref.mounted) return;
    final now = _nowMs();
    _steps = total;
    _cadence.add(now, total);
    if (!_gap.open || state.status != RecorderStatus.recording) return;
    _gap.steps(total);
    state = state.copyWith(meters: _gapBaseM + _gap.meters(_stride.strideM));
    _progress();
  }

  double? _stepSpeed(int now) {
    if (!_stepsOk) return null;
    final sps = _cadence.stepsPerSecond(now);
    return sps == null || sps <= 0 ? null : sps * _stride.strideM;
  }

  void _learnStride() {
    final steps = _steps;
    if (steps == null || _gap.open || state.signal != GpsSignal.good) {
      _learnSteps = null;
      return;
    }
    if (_learnSteps case final from?) {
      if (steps - from < minLearnSteps) return;
      _stride.learn(state.meters - _learnM, steps - from);
    }
    _learnSteps = steps;
    _learnM = state.meters;
  }

  void _closeGap() {
    if (!_gap.open) return;
    _extraM += _gap.meters(_stride.strideM);
    _gap.close();
    _learnSteps = null;
    state = state.copyWith(onSteps: false);
  }

  void _alert(String text) => unawaited(ref.read(speakerProvider).say(text));
}
