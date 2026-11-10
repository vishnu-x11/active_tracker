import 'dart:convert';

import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/running/domain/entities/run_settings.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/motion_detector.dart';
import 'package:active_tracker/features/running/domain/use_cases/voice_cues.dart';
import 'package:active_tracker/features/running/presentation/notifiers/run_recorder_notifier.dart';
import 'package:active_tracker/features/running/presentation/providers.dart';
import 'package:active_tracker/features/running/presentation/screens/run_record_screen.dart';
import 'package:active_tracker/features/running/presentation/states/run_recorder_state.dart';
import 'package:active_tracker/features/running/presentation/widgets/run_share_card.dart';
import 'package:active_tracker/features/running/domain/entities/run.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_speaker.dart';
import '../../helpers/pump.dart';
import 'gps_test.dart' show FakeLocation, track;

TrackPoint at(double metersNorth, {int t = 0}) => TrackPoint(lat: 12.9 + metersNorth / 111195, lng: 77.6, t: t);

void main() {
  group('speech', () {
    test('durations, paces and distances read naturally', () {
      expect(Speech.duration(60), '1 minute');
      expect(Speech.duration(330), '5 minutes 30 seconds');
      expect(Speech.duration(3725), '1 hour 2 minutes');
      expect(Speech.duration(0), '0 seconds');
      expect(Speech.pace(360), '6 minutes per kilometre');
      expect(Speech.pace(332), '5 minutes 32 per kilometre');
      expect(Speech.distance(400), '400 metres');
      expect(Speech.distance(1000), '1 kilometre');
      expect(Speech.distance(2500), '2.5 kilometres');
      expect(Speech.distance(1020), '1 kilometre');
      expect(Speech.distance(1960), '2 kilometres');
    });

    test('split cues fire once per mark', () {
      final cues = SplitCues(1000);
      expect(cues.check(meters: 999, seconds: 300), isNull);
      expect(
        cues.check(meters: 1000, seconds: 330),
        '1 kilometre. Time 5 minutes 30 seconds. Average pace 5 minutes 30 per kilometre.',
      );
      expect(cues.check(meters: 1500, seconds: 500), isNull);
      expect(
        cues.check(meters: 2100, seconds: 700),
        '2 kilometres. Time 11 minutes 40 seconds. Average pace 5 minutes 50 per kilometre.',
      );
      expect(SplitCues(0).check(meters: 5000, seconds: 100), isNull);
      expect(SplitCues(500, fromM: 1200).check(meters: 1400, seconds: 1), isNull);
      expect(SplitCues(500, fromM: 1200).check(meters: 1500, seconds: 450), startsWith('1.5 kilometres.'));
    });
  });

  group('workout coach', () {
    test('intervals walk through every step', () {
      const w = RunWorkout(kind: WorkoutKind.intervals, reps: 2, workM: 400, restSec: 60, warmupMin: 0);
      expect(w.steps.map((s) => s.kind), [StepKind.work, StepKind.rest, StepKind.work, StepKind.cooldown]);
      final c = WorkoutCoach(w);
      expect(c.view(meters: 0, seconds: 0)!.title, 'Intervals ready');
      expect(c.update(meters: 0, seconds: 0), ['Rep 1 of 2. Run 400 metres.']);
      expect(c.view(meters: 160, seconds: 40)!.detail, '240 m left');
      expect(c.update(meters: 400, seconds: 120), ['Rest for 1 minute.']);
      expect(c.view(meters: 400, seconds: 135), (title: 'Rep 1/2 · Rest', detail: '0:45 left', done: false));
      expect(c.update(meters: 410, seconds: 181), ['Rep 2 of 2. Run 400 metres.']);
      expect(c.update(meters: 810, seconds: 300), ['Intervals done. Cool down, then finish when ready.']);
      expect(c.view(meters: 900, seconds: 330)!.title, 'Cool-down');
      expect(c.update(meters: 5000, seconds: 3000), isEmpty);
    });

    test('a warm-up comes first and each step counts from where it began', () {
      const w = RunWorkout(kind: WorkoutKind.intervals, reps: 1, workM: 200, warmupMin: 5);
      final c = WorkoutCoach(w);
      expect(c.update(meters: 0, seconds: 0), ['Warm up for 5 minutes.']);
      expect(c.update(meters: 1500, seconds: 400), ['Rep 1 of 1. Run 200 metres.']);
      expect(c.update(meters: 1700, seconds: 450), ['Intervals done. Cool down, then finish when ready.']);
    });

    test('target pace nudges at most once a minute', () {
      final c = WorkoutCoach(const RunWorkout(kind: WorkoutKind.targetPace, targetPaceSec: 360));
      expect(c.update(meters: 0, seconds: 0), ['Target pace 6 minutes per kilometre.']);
      expect(c.update(meters: 500, seconds: 30, pace: 400), isEmpty);
      expect(c.update(meters: 1000, seconds: 61, pace: 400), ['Speed up. Pace 6 minutes 40 per kilometre.']);
      expect(c.update(meters: 1100, seconds: 70, pace: 300), isEmpty);
      expect(c.update(meters: 1300, seconds: 125, pace: 300), ['Ease off. Pace 5 minutes per kilometre.']);
      expect(c.update(meters: 1500, seconds: 200, pace: 365), isEmpty);
      expect(c.view(meters: 1500, seconds: 200, pace: 365)!.detail, 'On pace');
      expect(c.view(meters: 1500, seconds: 200, pace: 380)!.detail, '20s slower');
    });

    test('settings survive a round trip and clamp bad values', () {
      const s = RunSettings(
        autoPause: false,
        splitEveryM: 500,
        workout: RunWorkout(kind: WorkoutKind.intervals, reps: 8, workM: 800),
      );
      expect(RunSettings.fromMap(jsonDecode(jsonEncode(s.toMap())) as Map<String, Object?>), s);
      expect(const RunWorkout().copyWith(reps: 0, workM: 99999).reps, 1);
      expect(const RunWorkout().copyWith(workM: 99999).workM, 5000);
      expect(s.autoPauseActive, isFalse);
      expect(const RunSettings(workout: RunWorkout(kind: WorkoutKind.intervals)).autoPauseActive, isFalse);
      expect(const RunSettings().autoPauseActive, isTrue);
    });
  });

  test('motion detector ignores GPS jitter', () {
    final m = MotionDetector()..reset(0, at(0));
    expect(m.onFix(at(2), 1000), isFalse);
    expect(m.isStill(7000), isFalse);
    expect(m.onFix(at(3), 7500), isFalse);
    expect(m.isStill(8000), isTrue);
    expect(m.onFix(at(7), 9000), isTrue);
    expect(m.isStill(9500), isFalse);
  });

  test('losing the GPS signal is not standing still; speed counts as moving', () {
    final m = MotionDetector()..reset(0, at(0));
    expect(m.onFix(at(1), 1000), isFalse);
    expect(m.isStill(20000), isFalse);
    expect(m.onFix(at(1), 20000, speed: 2.5), isTrue);
    expect(m.onFix(at(1), 29000), isFalse);
    expect(m.isStill(29000), isTrue);
  });

  testWidgets('auto-pause stops the clock, moving resumes it, and the voice coach speaks', (tester) async {
    final gps = FakeLocation()..here = at(0);
    final speaker = FakeSpeaker();
    var now = DateTime(2026, 11, 9, 7);
    await pumpFeature(
      tester,
      routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
      initial: '/rec',
      speaker: speaker,
      overrides: [locationSourceProvider.overrideWithValue(gps), recorderClockProvider.overrideWithValue(() => now)],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
    RunRecorderState s() => container.read(runRecorderProvider);

    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    expect(gps.backgroundCalls.last, isTrue);
    expect(speaker.said, contains('Run started.'));

    final start = now;
    for (final (i, p) in track(102, startT: start.millisecondsSinceEpoch).indexed) {
      now = start.add(Duration(seconds: i * 3));
      gps.controller.add(p);
      await tester.pump();
    }
    expect(s().km, closeTo(1.01, 0.01));
    expect(speaker.said.where((l) => l.startsWith('1 kilometre.')), hasLength(1));

    now = now.add(const Duration(seconds: 9));
    await tester.pump(const Duration(seconds: 1));
    expect(s().status, RecorderStatus.recording);
    final last = s().points.last;
    gps.controller.add(TrackPoint(lat: last.lat, lng: last.lng, t: now.millisecondsSinceEpoch));
    await tester.pump(const Duration(seconds: 1));
    expect(s().status, RecorderStatus.autoPaused);
    expect(find.text('Auto-paused'), findsOneWidget);
    expect(s().elapsedMs, 303000);
    expect(speaker.said.last, 'Auto-paused.');

    now = now.add(const Duration(seconds: 30));
    gps.controller.add(track(1, startLat: 12.9 + 1020 / 111195, startT: now.millisecondsSinceEpoch).single);
    await tester.pump();
    expect(s().status, RecorderStatus.recording);
    expect(s().segment, 1);
    expect(s().elapsedMs, 303000);
    expect(speaker.said.last, 'Resumed.');

    await tester.tap(find.text('Finish'));
    await settleWithIo(tester, rounds: 10);
    expect(speaker.said.last, startsWith('Run finished. 1 kilometre in 5 minutes'));
    expect(await tester.runAsync(() => container.read(appDatabaseProvider).setting('run.recording')), isNull);
  });

  testWidgets('run settings: switching to intervals is saved and turns auto-pause off', (tester) async {
    final gps = FakeLocation()..here = at(0);
    final db = await pumpFeature(
      tester,
      routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
      initial: '/rec',
      height: 2532,
      overrides: [locationSourceProvider.overrideWithValue(gps)],
    );
    await tester.tap(find.byTooltip('Run settings'));
    await tester.pumpAndSettle();
    expect(find.text('Pauses when you stop, resumes when you move'), findsOneWidget);
    await tester.tap(find.text('Intervals'));
    await settleWithIo(tester);
    expect(find.text('Off during intervals, so rests keep counting'), findsOneWidget);
    await tester.tap(find.byTooltip('More Repeats'));
    await settleWithIo(tester);
    expect(find.text('7 ×'), findsOneWidget);

    final saved = await tester.runAsync(() => db.setting('run.settings'));
    final settings = RunSettings.fromMap(jsonDecode(saved!) as Map<String, Object?>);
    expect(settings.workout.kind, WorkoutKind.intervals);
    expect(settings.workout.reps, 7);
    expect(settings.autoPauseActive, isFalse);

    await tester.tap(find.byTooltip('Close').last);
    await tester.pumpAndSettle();
    expect(find.text('Intervals ready'), findsOneWidget);
  });

  testWidgets('the run share card draws the route and the stats', (tester) async {
    final run = Run(
      id: 'r',
      day: '2026-11-09',
      startedAt: DateTime(2026, 11, 9, 7),
      title: 'Morning Run',
      type: RunType.outdoor,
      source: RunSource.gps,
      distanceM: 5200,
      movingSec: 1775,
      weightKg: 75,
      kcal: 405,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: RunShareCard(run: run, points: track(60, segment: 0)),
        ),
      ),
    );
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.textContaining('5:41', findRichText: true), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('table name for settings exists', () => expect(Tables.all, contains(Tables.settings)));
}
