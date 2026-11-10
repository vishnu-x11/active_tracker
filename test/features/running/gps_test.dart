import 'dart:async';

import 'package:active_tracker/features/running/data/data_sources/location_source.dart';
import 'package:active_tracker/features/running/domain/entities/track_point.dart';
import 'package:active_tracker/features/running/domain/use_cases/track_math.dart';
import 'package:active_tracker/features/running/presentation/notifiers/run_recorder_notifier.dart';
import 'package:active_tracker/features/running/presentation/providers.dart';
import 'package:active_tracker/features/running/presentation/screens/run_log_screen.dart';
import 'package:active_tracker/features/running/presentation/screens/run_record_screen.dart';
import 'package:active_tracker/features/running/running_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';

List<TrackPoint> track(
  int n, {
  double stepM = 10,
  int stepS = 3,
  int startT = 0,
  int segment = 0,
  double startLat = 12.9,
}) => [
  for (var i = 0; i < n; i++)
    TrackPoint(lat: startLat + i * stepM / 111195, lng: 77.6, t: startT + i * stepS * 1000, segment: segment),
];

class FakeLocation implements LocationSource {
  final controller = StreamController<TrackPoint>.broadcast();
  LocationProblem? problem;

  @override
  Future<LocationProblem?> ensureAccess() async => problem;

  TrackPoint? here;

  @override
  Future<TrackPoint?> current() async => here;

  final backgroundCalls = <bool>[];

  @override
  Stream<GpsFix> fixes({bool background = false}) {
    backgroundCalls.add(background);
    return controller.stream.map(GpsFix.new);
  }

  @override
  Future<void> openSettings() async {}
}

void main() {
  group('TrackMath', () {
    test('distance and moving time', () {
      final t = track(101);
      expect(TrackMath.distance(t), closeTo(1000, 1));
      expect(TrackMath.movingSeconds(t).last, 300);
    });

    test('a pause adds neither distance nor time', () {
      final a = track(51);
      final b = track(51, startT: 3600 * 1000, segment: 1, startLat: 12.9 + 1000 / 111195);
      final t = [...a, ...b];
      expect(TrackMath.distance(t), closeTo(1000, 1));
      expect(TrackMath.movingSeconds(t).last, 300);
    });

    test('splits per km and the partial last km', () {
      final s = TrackMath.splits(track(251));
      expect(s.map((x) => x.km), [1, 1, closeTo(0.5, 0.01)]);
      expect(s.first.seconds, closeTo(300, 1));
    });

    test('best effort finds the fastest stretch inside the run', () {
      final slow = track(101);
      final fast = track(100, stepS: 2, startT: 300000 + 2000, startLat: 12.9 + 1010 / 111195);
      final best = TrackMath.bestEffort([...slow, ...fast], 1000)!;
      expect(best, closeTo(200, 6));
      expect(TrackMath.bestEffort(slow, 5000), isNull);
    });

    test('elevation gain ignores small noise', () {
      final pts = [
        for (final (i, a) in <double>[100, 100.5, 103, 102, 107].indexed) TrackPoint(lat: 0, lng: 0, t: i, alt: a),
      ];
      expect(TrackMath.elevationGain(pts), 8);
    });
  });

  testWidgets('record → pause → resume → finish → run log filled from GPS → save', (tester) async {
    final gps = FakeLocation()..here = const TrackPoint(lat: 12.9, lng: 77.6, t: 0);
    await pumpFeature(
      tester,
      routes: [
        GoRoute(
          path: '/start',
          builder: (c, s) => TextButton(onPressed: () => c.push('/rec'), child: const Text('go')),
        ),
        GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen()),
        ...RunRoutes.routes().where((r) => r is GoRoute && r.path != RunRoutes.record),
      ],
      initial: '/start',
      height: 6000,
      overrides: [locationSourceProvider.overrideWithValue(gps)],
    );
    await tester.tap(find.text('go'));
    await settleWithIo(tester);
    expect(find.text('Ready'), findsOneWidget);

    final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
    expect(container.read(runRecorderProvider).here, gps.here);
    final walkTo = track(1, startLat: 12.95).single;
    gps.controller.add(walkTo);
    await settleWithIo(tester);
    expect(container.read(runRecorderProvider).here, walkTo);
    expect(container.read(runRecorderProvider).points, isEmpty);

    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    expect(find.text('Recording'), findsOneWidget);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in track(101, startT: now)) {
      gps.controller.add(p);
    }
    await settleWithIo(tester);
    expect(find.text('1.00 km'), findsOneWidget);

    await tester.tap(find.text('Pause'));
    await tester.pump();
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    gps.controller.add(track(1, startT: now + 999000, startLat: 13.5).single);
    await settleWithIo(tester);
    expect(find.text('1.00 km'), findsOneWidget);

    await tester.tap(find.text('Finish'));
    await settleWithIo(tester, rounds: 10);
    expect(find.byType(RunLogScreen), findsOneWidget);
    expect(find.text('Save GPS run'), findsOneWidget);
    expect(find.text('Auto-filled'), findsOneWidget);
    expect(find.text('Going for a run now?'), findsNothing);

    await tester.tap(find.textContaining('Save run'));
    await settleWithIo(tester, rounds: 12);
    expect(find.text('1.00 km'), findsWidgets);
    expect(find.textContaining('Recorded with GPS'), findsOneWidget);
    expect(find.text('Pace per km'), findsOneWidget);
  });

  testWidgets('a run in progress survives the app closing and can be discarded', (tester) async {
    final gps = FakeLocation()..here = const TrackPoint(lat: 12.9, lng: 77.6, t: 0);
    final db = await pumpFeature(
      tester,
      routes: [
        GoRoute(
          path: '/start',
          builder: (c, s) => TextButton(onPressed: () => c.push('/rec'), child: const Text('go')),
        ),
        GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen()),
      ],
      initial: '/start',
      overrides: [locationSourceProvider.overrideWithValue(gps)],
    );
    await tester.tap(find.text('go'));
    await settleWithIo(tester);
    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final p in track(51, startT: now)) {
      gps.controller.add(p);
    }
    await settleWithIo(tester);
    await tester.tap(find.text('Pause'));
    await settleWithIo(tester);
    expect(await tester.runAsync(() => db.setting('run.recording')), isNotNull);

    final container = ProviderScope.containerOf(tester.element(find.byType(RunRecordScreen)));
    container.invalidate(runRecorderProvider);
    await settleWithIo(tester);
    final restored = container.read(runRecorderProvider);
    expect(restored.restored, isTrue);
    expect(restored.points, hasLength(51));
    expect(find.text('0.50 km'), findsOneWidget);
    expect(find.text('Paused'), findsOneWidget);
    expect(find.text('We kept your unfinished run. Tap Resume to carry on.'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await settleWithIo(tester);
    expect(find.text('go'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('run.recording')), isNull);
  });

  testWidgets('location blocked shows the reason', (tester) async {
    final gps = FakeLocation()..problem = LocationProblem.deniedForever;
    await pumpFeature(
      tester,
      routes: [GoRoute(path: '/rec', builder: (c, s) => const RunRecordScreen())],
      initial: '/rec',
      overrides: [locationSourceProvider.overrideWithValue(gps)],
    );
    await tester.tap(find.text('Start'));
    await settleWithIo(tester);
    expect(find.textContaining('Location access is blocked'), findsOneWidget);
    expect(find.text('Ready'), findsOneWidget);
  });
}
