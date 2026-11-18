import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/presentation/notifiers/run_recorder_notifier.dart';
import 'package:active_tracker/features/running/presentation/providers.dart';
import 'package:active_tracker/features/running/presentation/screens/run_record_screen.dart';
import 'package:active_tracker/features/running/presentation/states/run_recorder_state.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_speaker.dart';
import '../../helpers/fake_steps.dart';
import '../../helpers/pump.dart';
import 'gps_test.dart' show FakeLocation;

TrackPoint north(double m, int t) => TrackPoint(lat: 12.9 + m / 111195, lng: 77.6, t: t);

void main() {
  testWidgets('GPS drops mid-run: voice alert, GPS restarted, steps keep distance and pace, gap bridged on return', (
    tester,
  ) async {
    final gps = FakeLocation()..here = north(0, 0);
    final steps = FakeSteps(allowed: true);
    final speaker = FakeSpeaker();
    var now = DateTime(2026, 11, 18, 6);
    final db = await pumpFeature(
      tester,
      routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
      initial: '/rec',
      speaker: speaker,
      steps: steps,
      overrides: [locationSourceProvider.overrideWithValue(gps), recorderClockProvider.overrideWithValue(() => now)],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
    RunRecorderState s() => container.read(runRecorderProvider);

    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    expect(gps.rawCalls.last, isFalse);

    final start = now;
    for (var i = 0; i <= 100; i++) {
      now = start.add(Duration(seconds: i * 3));
      steps.controller.add(1000 + i * 8);
      gps.controller.add(north(i * 10.0, now.millisecondsSinceEpoch));
      await tester.pump(const Duration(seconds: 3));
    }
    expect(s().meters, closeTo(1000, 1));
    expect(s().signal, GpsSignal.good);
    final calls = gps.rawCalls.length;

    final lastGood = now;
    for (var sec = 1; sec <= 60; sec++) {
      now = lastGood.add(Duration(seconds: sec));
      steps.controller.add(1800 + sec * 3);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(s().signal, GpsSignal.lost);
    expect(speaker.said, contains(RunRecorderNotifier.lostWithSteps));
    expect(speaker.said.where((l) => l.startsWith('GPS disconnected')), hasLength(1));
    expect(gps.rawCalls.length, greaterThan(calls), reason: 'the dead GPS stream is rebuilt');
    expect(gps.rawCalls.skip(calls), contains(isTrue), reason: 'falls back to the raw GPS provider');
    expect(s().meters, closeTo(1000 + 180 * 1.25, 1));
    expect(s().currentPace, closeTo(1000 / (3 * 1.25), 1));
    expect(find.text('GPS disconnected · using steps'), findsOneWidget);
    expect(s().status, RecorderStatus.recording);

    now = now.add(const Duration(seconds: 1));
    gps.controller.add(north(1150, now.millisecondsSinceEpoch));
    await tester.pump();
    await tester.pump();
    expect(speaker.said.last, RunRecorderNotifier.backAgain);
    expect(s().signal, GpsSignal.good);
    expect(s().meters, closeTo(1225, 1), reason: 'steps (225 m) beat the 150 m straight line');
    expect(find.text('GPS disconnected · using steps'), findsNothing);

    await tester.tap(find.text('Finish'));
    await settleWithIo(tester, rounds: 10);
    final saved = await tester.runAsync(() => db.db.query(Tables.runs));
    expect(saved!.single['distance_m'], closeTo(1225, 1));
  });

  testWidgets('location switched off: alert at once, reconnect as soon as it is back on', (tester) async {
    final gps = FakeLocation()..here = north(0, 0);
    final speaker = FakeSpeaker();
    var now = DateTime(2026, 11, 18, 6);
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
    gps.controller.add(north(0, now.millisecondsSinceEpoch));
    await tester.pump(const Duration(seconds: 1));

    gps.on = false;
    gps.service.add(false);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(s().signal, GpsSignal.lost);
    expect(speaker.said.last, RunRecorderNotifier.lostNoSteps);
    expect(find.text('GPS disconnected'), findsOneWidget);

    final calls = gps.backgroundCalls.length;
    gps.on = true;
    gps.service.add(true);
    await settleWithIo(tester);
    expect(gps.backgroundCalls.length, greaterThan(calls));
    now = now.add(const Duration(seconds: 2));
    gps.controller.add(north(5, now.millisecondsSinceEpoch));
    await tester.pump();
    expect(s().signal, GpsSignal.good);
    expect(speaker.said.last, RunRecorderNotifier.backAgain);
  });

  testWidgets('in the background the GPS stream is never rebuilt; one-off fixes keep the route going', (tester) async {
    final gps = FakeLocation()..here = north(0, 0);
    var now = DateTime(2026, 11, 18, 6);
    await pumpFeature(
      tester,
      routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
      initial: '/rec',
      overrides: [locationSourceProvider.overrideWithValue(gps), recorderClockProvider.overrideWithValue(() => now)],
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
    RunRecorderState s() => container.read(runRecorderProvider);

    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    final start = now;
    for (var i = 0; i <= 10; i++) {
      now = start.add(Duration(seconds: i * 3));
      gps.controller.add(north(i * 10.0, now.millisecondsSinceEpoch));
      await tester.pump(const Duration(seconds: 3));
    }

    final binding = tester.binding;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    final streams = gps.backgroundCalls.length;

    var walked = 100.0;
    gps.onPoll = () => GpsFix(north(walked += 9, now.millisecondsSinceEpoch), accuracy: 5);
    for (var sec = 1; sec <= 40; sec++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(gps.backgroundCalls.length, streams, reason: 'no foreground-service restart from the background');
    expect(gps.polls, isNotEmpty);
    expect(s().signal, GpsSignal.good);
    expect(s().meters, greaterThan(150));

    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await settleWithIo(tester);
    expect(gps.backgroundCalls.length, greaterThan(streams), reason: 'rebuilt once the app is visible again');
    final polled = gps.polls.length;
    now = now.add(const Duration(seconds: 1));
    gps.controller.add(north(walked + 5, now.millisecondsSinceEpoch));
    await tester.pump(const Duration(seconds: 6));
    expect(gps.polls.length, polled, reason: 'polling stops once the stream delivers again');
  });

  testWidgets(
    '5 km run in the background: location turned off mid-run, alert at once, distance kept after re-enabling',
    (tester) async {
      final gps = FakeLocation()..here = north(0, 0);
      final steps = FakeSteps(allowed: true);
      final speaker = FakeSpeaker();
      var now = DateTime(2026, 11, 18, 6);
      await pumpFeature(
        tester,
        routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
        initial: '/rec',
        speaker: speaker,
        steps: steps,
        overrides: [locationSourceProvider.overrideWithValue(gps), recorderClockProvider.overrideWithValue(() => now)],
      );
      final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
      RunRecorderState s() => container.read(runRecorderProvider);

      await tester.tap(find.text('Start'));
      await settleWithIo(tester);
      final binding = tester.binding;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);

      final start = now;
      for (var i = 0; i <= 100; i++) {
        now = start.add(Duration(seconds: i * 3));
        steps.controller.add(1000 + i * 8);
        gps.controller.add(north(i * 10.0, now.millisecondsSinceEpoch));
        await tester.pump(const Duration(seconds: 3));
      }
      expect(s().meters, closeTo(1000, 1));

      gps.on = false;
      gps.service.add(false);
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 100));
      expect(s().signal, GpsSignal.lost);
      expect(speaker.said.last, RunRecorderNotifier.lostWithSteps, reason: 'spoken at once, not after 15 s');

      for (var sec = 1; sec <= 20; sec++) {
        now = now.add(const Duration(seconds: 1));
        steps.controller.add(1800 + sec * 3);
        await tester.pump(const Duration(seconds: 1));
      }
      expect(s().meters, closeTo(1000 + 60 * 1.25, 1), reason: 'steps keep counting while location is off');

      final streams = gps.backgroundCalls.length;
      var walked = 1075.0;
      gps.onPoll = () => GpsFix(north(walked += 4, now.millisecondsSinceEpoch), accuracy: 5);
      gps.on = true;
      gps.service.add(true);
      for (var sec = 1; sec <= 6; sec++) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
      }
      expect(gps.backgroundCalls.length, streams, reason: 'no foreground-service restart from the background');
      expect(s().signal, GpsSignal.good);
      expect(speaker.said.last, RunRecorderNotifier.backAgain);
      expect(s().meters, greaterThan(1075));
      expect(s().meters, lessThan(1100));
      expect(s().status, RecorderStatus.recording);
    },
  );
}
