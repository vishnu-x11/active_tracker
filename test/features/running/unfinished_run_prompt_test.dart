import 'package:active_tracker/core/dates.dart';
import 'package:active_tracker/features/running/data/repositories/recording_repository_impl.dart';
import 'package:active_tracker/features/running/domain/entities/recording.dart';
import 'package:active_tracker/features/running/presentation/widgets/unfinished_run_prompt.dart';
import 'package:active_tracker/features/running/running_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';
import 'gps_test.dart' show track;

void main() {
  final routes = [
    GoRoute(
      path: '/home',
      builder: (c, s) => const UnfinishedRunPrompt(child: Text('home')),
    ),
    GoRoute(path: RunRoutes.record, builder: (c, s) => const Text('recorder')),
  ];

  Recording unfinished(DateTime start) => Recording(
    points: track(51, startT: start.millisecondsSinceEpoch),
    segment: 0,
    movingMs: 150000,
    savedAt: start.add(const Duration(minutes: 3)),
  );

  Future<void> background(WidgetTester tester) async {
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump();
  }

  Future<void> foreground(WidgetTester tester) async {
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settleWithIo(tester);
  }

  testWidgets('a run left unsaved days ago is still offered when the app opens', (tester) async {
    final start = DateTime.now().subtract(const Duration(days: 3));
    await pumpFeature(
      tester,
      routes: routes,
      initial: '/home',
      seed: (db) => RecordingRepositoryImpl(db).save(unfinished(start)),
    );
    await settleWithIo(tester);
    expect(find.text('Resume your unfinished run?'), findsOneWidget);
    expect(find.textContaining('0.50 km'), findsOneWidget);
    expect(find.textContaining('on ${shortDate(start)}'), findsOneWidget);

    await tester.tap(find.text('Resume'));
    await settleWithIo(tester);
    expect(find.text('recorder'), findsOneWidget);
  });

  testWidgets('coming back to the app offers a run that was left unsaved', (tester) async {
    final db = await pumpFeature(tester, routes: routes, initial: '/home');
    await settleWithIo(tester);
    expect(find.text('Resume your unfinished run?'), findsNothing);

    await background(tester);
    await tester.runAsync(() => RecordingRepositoryImpl(db).save(unfinished(DateTime.now())));
    await foreground(tester);
    expect(find.text('Resume your unfinished run?'), findsOneWidget);
    expect(find.textContaining('today'), findsOneWidget);

    await tester.tap(find.text('Discard'));
    await settleWithIo(tester);
    expect(find.text('home'), findsOneWidget);
    expect(await tester.runAsync(() => db.setting('run.recording')), isNull);

    await background(tester);
    await foreground(tester);
    expect(find.text('Resume your unfinished run?'), findsNothing);
  });
}
