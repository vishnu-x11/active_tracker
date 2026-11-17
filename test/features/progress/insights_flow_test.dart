import 'package:active_tracker/core/formulas/formulas.dart';
import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/progress/progress_routes.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_insights.dart';
import 'package:active_tracker/features/running/domain/use_cases/run_metrics.dart';
import 'package:active_tracker/features/running/running_api.dart';
import 'package:active_tracker/features/running/running_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';
import '../../helpers/seed.dart';
import '../running/gps_test.dart' show track;

Future<void> seedRuns(AppDatabase db) async {
  final s = Seed(db);
  for (var i = 1; i <= 5; i++) {
    final at = DateTime(2026, 11, 16 - i, 7);
    await s.run(at, kcal: 270, km: 3.5, seconds: 1050);
    final id = 'r${i - 1}';
    for (final (n, p) in track(351, startT: at.millisecondsSinceEpoch).indexed) {
      await db.db.insert(Tables.runPoints, {
        'run_sync_id': id,
        'seq': n,
        'lat': p.lat,
        'lng': p.lng,
        't': p.t,
        'segment': 0,
      });
    }
  }
}

void main() {
  testWidgets('insight cards, zones and the zone editor, then the training log', (tester) async {
    final root = GlobalKey<NavigatorState>();
    final db = await pumpFeature(
      tester,
      routes: [
        GoRoute(
          path: '/day',
          builder: (c, s) => const Scaffold(body: Text('Day opened')),
        ),
        ShellRoute(
          builder: (c, s, child) => Scaffold(body: child),
          routes: [
            ProgressRoutes.tab(root, insights: const [RunInsightCards()], dayRoute: '/day'),
          ],
        ),
        ...RunRoutes.routes(),
      ],
      initial: ProgressRoutes.progress,
      height: 9000,
      navigatorKey: root,
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 16))],
      seed: seedRuns,
    );
    await settleWithIo(tester, rounds: 20);

    final tenK = RunMetrics.clock(RacePredictor.riegel(1050, 3500, 10000).round());
    expect(find.text('PERFORMANCE PREDICTIONS'), findsOneWidget);
    expect(find.text(tenK), findsOneWidget);
    expect(find.text('100% in Z5'), findsOneWidget);
    expect(find.text('LAST 3 MONTHS'), findsOneWidget);
    expect(find.text('1h per week'), findsOneWidget);
    expect(find.text('1 week in a row · best 1'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('1 km best effort, 5:00')), findsOneWidget);

    await tester.tap(find.text('TRAINING ZONES · PACE'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('100% in Zone 5'), findsOneWidget);
    expect(find.textContaining('Most of your running this month was in Zone 5'), findsOneWidget);

    await tester.tap(find.byTooltip('Edit zones'));
    await settleWithIo(tester, rounds: 10);
    final threshold = (RacePredictor.riegel(1050, 3500, 10000) / 10).round();
    expect(find.text('${formatPace(threshold.toDouble())} /km'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.enterText(find.byType(TextField).first, '5:00');
    await tester.tap(find.text('Fill zones'));
    await tester.pump();
    await tester.tap(find.text('Save pace zones'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('Training zones'), findsOneWidget);
    final saved = (await tester.runAsync(() => db.db.query(Tables.profile)))!.single['pace_zones'];
    expect(saved, contains('"auto":false'));
    expect(saved, contains('"bounds":[267,284,309,345,390]'));
    expect(find.text('100% in Zone 4'), findsOneWidget);

    await tester.pageBack();
    await settleWithIo(tester);
    await tester.tap(find.text('PERFORMANCE PREDICTIONS'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('CURRENT PREDICTION'), findsOneWidget);
    await tester.tap(find.text('Today'));
    await settleWithIo(tester);
    expect(find.text('Marathon'), findsOneWidget);
    await tester.pageBack();
    await settleWithIo(tester);

    await tester.tap(find.text('TRAINING LOG'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('Training log'), findsOneWidget);
    await tester.tap(find.bySemanticsLabel(RegExp('^Sunday 15 November, 18 min run')));
    await settleWithIo(tester);
    expect(find.text('Day opened'), findsOneWidget);
  });

  testWidgets('run detail shows the best ranked effort', (tester) async {
    await pumpFeature(
      tester,
      routes: RunRoutes.routes(),
      initial: RunRoutes.detail('r4'),
      height: 6000,
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 16))],
      seed: seedRuns,
    );
    await settleWithIo(tester, rounds: 20);
    expect(find.text('Your fastest 1 km!'), findsOneWidget);
    expect(find.text('Also fastest 400 m'), findsOneWidget);
  });
}
