import 'dart:async';

import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/presentation/notifiers/run_recorder_notifier.dart';
import 'package:active_tracker/features/running/presentation/providers.dart';
import 'package:active_tracker/features/running/presentation/screens/run_record_screen.dart';
import 'package:active_tracker/features/running/presentation/states/run_recorder_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/fake_speaker.dart';
import '../../helpers/fake_steps.dart';
import '../../helpers/pump.dart';
import 'gps_test.dart' show FakeLocation;

TrackPoint at(double northM, int t, {double eastM = 0}) =>
    TrackPoint(lat: 12.9 + northM / 111195, lng: 77.6 + eastM / 108370, t: t);

class Run {
  Run(this.tester, this.gps, this.steps, this.speaker, this.clock);

  final WidgetTester tester;
  final FakeLocation gps;
  final FakeSteps steps;
  final FakeSpeaker speaker;
  final DateTime Function() clock;
  late ProviderContainer container;

  RunRecorderState get s => container.read(runRecorderProvider);
  RunRecorderNotifier get n => container.read(runRecorderProvider.notifier);
  int get ms => clock().millisecondsSinceEpoch;
  int said(String line) => speaker.said.where((l) => l == line).length;
}

Future<Run> startRun(WidgetTester tester, {required DateTime Function() clock}) async {
  final gps = FakeLocation()..here = at(0, 0);
  final steps = FakeSteps(allowed: true);
  final speaker = FakeSpeaker();
  await pumpFeature(
    tester,
    routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
    initial: '/rec',
    speaker: speaker,
    steps: steps,
    overrides: [locationSourceProvider.overrideWithValue(gps), recorderClockProvider.overrideWithValue(clock)],
  );
  final run = Run(tester, gps, steps, speaker, clock)
    ..container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
  await tester.tap(find.text('Start'));
  await settleWithIo(tester);
  return run;
}

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 11, 20, 6));

  Future<void> runNorth(Run r, {required int fixes, double fromM = 0, int fromSteps = 1000}) async {
    final start = now;
    for (var i = 0; i < fixes; i++) {
      now = start.add(Duration(seconds: i * 3));
      r.steps.controller.add(fromSteps + i * 8);
      r.gps.controller.add(at(fromM + i * 10.0, r.ms));
      await r.tester.pump(const Duration(seconds: 3));
    }
  }

  Future<void> seconds(Run r, int n, {void Function(int sec)? each}) async {
    for (var sec = 1; sec <= n; sec++) {
      now = now.add(const Duration(seconds: 1));
      each?.call(sec);
      await r.tester.pump(const Duration(seconds: 1));
    }
  }

  testWidgets('a stale fix repeated by the phone does not hide a GPS loss; the alert repeats every 5 s', (
    tester,
  ) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 30);
    final last = at(290, r.ms);
    const stepsAt = 1000 + 29 * 8;

    await seconds(
      r,
      9,
      each: (sec) {
        r.gps.controller.add(last);
        r.steps.controller.add(stepsAt + sec * 3);
      },
    );
    expect(r.s.signal, isNot(GpsSignal.lost));
    expect(r.said(RunRecorderNotifier.lost), 0);

    await seconds(
      r,
      21,
      each: (sec) {
        r.gps.controller.add(last);
        r.steps.controller.add(stepsAt + (9 + sec) * 3);
      },
    );
    expect(r.s.signal, GpsSignal.lost);
    expect(r.said(RunRecorderNotifier.lost), 5, reason: 'at 10, 15, 20, 25 and 30 s');
    expect(r.s.status, RecorderStatus.recording);
    expect(r.s.meters, greaterThan(290 + 80));
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('GPS dying while the run is auto-paused is still announced; running again resumes it from steps', (
    tester,
  ) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 30);
    final stop = at(290, r.ms);
    const stepsAt = 1000 + 29 * 8;
    await seconds(r, 12, each: (_) => r.gps.controller.add(at(290, r.ms)));
    expect(r.s.status, RecorderStatus.autoPaused);
    expect(stop.lat, r.s.points.last.lat);

    await seconds(r, 12);
    expect(r.s.signal, GpsSignal.lost);
    expect(r.said(RunRecorderNotifier.lost), greaterThanOrEqualTo(1));
    expect(r.s.status, RecorderStatus.autoPaused);
    final before = r.s.meters;

    await seconds(r, 6, each: (sec) => r.steps.controller.add(stepsAt + sec * 3));
    expect(r.s.status, RecorderStatus.recording);
    await seconds(r, 10, each: (sec) => r.steps.controller.add(stepsAt + (6 + sec) * 3));
    expect(r.s.meters, greaterThan(before + 20), reason: 'steps carry the distance while GPS is out');
    expect(r.speaker.said.last, RunRecorderNotifier.lost);
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('frozen GPS while the steps say running: no auto-pause, alert, steps fill the distance', (tester) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 30);
    const stepsAt = 1000 + 29 * 8;
    final before = r.s.meters;
    await seconds(
      r,
      40,
      each: (sec) {
        r.gps.controller.add(at(290, r.ms));
        r.steps.controller.add(stepsAt + sec * 3);
      },
    );
    expect(r.s.status, RecorderStatus.recording);
    expect(r.speaker.said, isNot(contains('Auto-paused.')));
    expect(r.s.signal, GpsSignal.lost);
    expect(r.said(RunRecorderNotifier.lost), greaterThanOrEqualTo(5));
    expect(r.said(RunRecorderNotifier.backAgain), 0, reason: 'frozen fixes never count as a reconnect');
    expect(r.s.meters - before, closeTo(120 * 1.25, 2), reason: 'every step since GPS froze is counted');

    now = now.add(const Duration(seconds: 1));
    r.steps.controller.add(stepsAt + 123);
    r.gps.raw.add(GpsFix(at(290, r.ms, eastM: 3), accuracy: 5, speed: 2.5));
    await tester.pump();
    expect(r.s.signal, GpsSignal.good);
    expect(r.speaker.said.last, RunRecorderNotifier.backAgain);
    expect(
      r.s.meters - before,
      closeTo(123 * 1.25, 2),
      reason: 'a lap ending near the frozen spot still keeps the steps',
    );
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('paused while GPS is off: turning location back on resumes the run by itself', (tester) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 30);

    r.gps.on = false;
    r.gps.service.add(false);
    await seconds(r, 1);
    expect(r.s.signal, GpsSignal.lost);
    expect(r.speaker.said.last, RunRecorderNotifier.lostLocationOff);

    r.n.pause();
    await seconds(r, 30);
    expect(r.s.status, RecorderStatus.paused);
    final alerts = r.said(RunRecorderNotifier.lostLocationOff);
    await seconds(r, 10);
    expect(r.said(RunRecorderNotifier.lostLocationOff), alerts, reason: 'no repeats while the runner has paused');

    r.gps.on = true;
    r.gps.service.add(true);
    await settleWithIo(tester);
    r.gps.controller.add(at(300, r.ms));
    await tester.pump();
    expect(r.s.status, RecorderStatus.recording);
    expect(r.s.signal, GpsSignal.good);
    expect(r.speaker.said.last, RunRecorderNotifier.backAndResumed);
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('paused by the runner with good GPS stays paused', (tester) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 10);
    r.n.pause();
    await seconds(r, 5, each: (_) => r.gps.controller.add(at(90, r.ms)));
    expect(r.s.status, RecorderStatus.paused);
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('weak fixes while disconnected do not flip the state or spam the alert', (tester) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 30);
    await seconds(r, 30, each: (sec) => r.gps.raw.add(GpsFix(at(290 + sec * 3.0, r.ms), accuracy: 60)));
    expect(r.s.signal, GpsSignal.lost);
    expect(r.said(RunRecorderNotifier.lost), 5);
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('a short weak patch on a bend is bridged with steps instead of a straight line', (tester) async {
    final r = await startRun(tester, clock: clock);
    await runNorth(r, fixes: 40);
    final before = r.s.meters;
    const stepsAt = 1000 + 39 * 8;
    await seconds(
      r,
      9,
      each: (sec) {
        r.steps.controller.add(stepsAt + sec * 3);
        r.gps.raw.add(GpsFix(at(390, r.ms, eastM: sec * 3.0), accuracy: 40));
      },
    );
    now = now.add(const Duration(seconds: 1));
    r.steps.controller.add(stepsAt + 30);
    r.gps.controller.add(at(400, r.ms));
    await tester.pump();
    expect(r.s.signal, GpsSignal.good);
    expect(
      r.s.meters - before,
      closeTo(30 * 1.25, 1),
      reason: '30 steps at the learned 1.25 m stride, not the 10 m chord',
    );
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });
}
