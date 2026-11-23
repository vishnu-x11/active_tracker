import 'dart:async';

import 'package:active_tracker/features/running/domain/entities/gps_fix.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump.dart';
import 'gps_alert_test.dart' show at, startRun;

void main() {
  late DateTime now;
  DateTime clock() => now;

  setUp(() => now = DateTime(2026, 11, 23, 7));

  testWidgets('standing after Start: the clock waits, no auto-pause, then counts from the first stride', (
    tester,
  ) async {
    final r = await startRun(tester, clock: clock);
    for (var sec = 1; sec <= 20; sec++) {
      now = now.add(const Duration(seconds: 1));
      r.gps.raw.add(GpsFix(at(0, r.ms), accuracy: 5));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(r.s.waiting, isTrue);
    expect(r.s.elapsedMs, 0);
    expect(find.text('Start moving'), findsOneWidget);
    expect(r.speaker.said, isNot(contains('Auto-paused.')));
    expect(r.s.avgPace, isNull);

    for (var sec = 1; sec <= 60; sec++) {
      now = now.add(const Duration(seconds: 1));
      r.gps.raw.add(GpsFix(at(sec * 3.0, r.ms), accuracy: 5, speed: 3));
      await tester.pump(const Duration(seconds: 1));
      if (sec == 30) expect(r.s.avgPace, isNull, reason: 'hidden for the first 100 m');
    }
    expect(r.s.waiting, isFalse);
    expect(find.text('Recording'), findsOneWidget);
    expect(r.s.elapsedMs, inInclusiveRange(59000, 60000));
    expect(r.s.avgPace, closeTo(1000 / 3, 6), reason: '3 m/s is 5:33 /km, not slowed by the 20 s spent standing');
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('steps start the clock even before GPS shows movement', (tester) async {
    final r = await startRun(tester, clock: clock);
    for (var sec = 1; sec <= 10; sec++) {
      now = now.add(const Duration(seconds: 1));
      if (sec > 4) r.steps.controller.add(500 + sec * 3);
      await tester.pump(const Duration(seconds: 1));
    }
    expect(r.s.waiting, isFalse);
    expect(r.s.elapsedMs, inInclusiveRange(3000, 5000));
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });

  testWidgets('no movement signal at all: after 30 s the clock counts from Start so no running time is lost', (
    tester,
  ) async {
    final r = await startRun(tester, clock: clock);
    for (var sec = 1; sec <= 31; sec++) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
    }
    expect(r.s.waiting, isFalse);
    expect(r.s.elapsedMs, inInclusiveRange(30000, 31000));
    unawaited(r.n.discard());
    await settleWithIo(tester);
  });
}
