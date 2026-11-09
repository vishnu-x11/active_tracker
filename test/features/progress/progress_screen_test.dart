import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/features/progress/progress_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';
import '../../helpers/seed.dart';

void main() {
  testWidgets('calendar: missed-goal badges, day dialog, closes without OK', (tester) async {
    final root = GlobalKey<NavigatorState>();
    await pumpFeature(
      tester,
      routes: [
        ShellRoute(
          builder: (c, s, child) => Scaffold(body: child),
          routes: [ProgressRoutes.tab(root)],
        ),
      ],
      initial: ProgressRoutes.progress,
      height: 7000,
      navigatorKey: root,
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 5))],
      seed: (db) async {
        final s = Seed(db);
        await s.gym(DateTime(2026, 11, 2, 19), kcal: 655);
        await s.run(DateTime(2026, 11, 4, 6, 40), kcal: 405);
      },
    );
    await settleWithIo(tester, rounds: 10);
    expect(find.text('Nov 2026'), findsOneWidget);
    expect(find.bySemanticsLabel('2 November, gym, missed water, protein'), findsOneWidget);
    expect(find.bySemanticsLabel('3 November, missed burn, water, protein'), findsOneWidget);
    expect(find.bySemanticsLabel('1 November'), findsOneWidget);
    expect(find.bySemanticsLabel('5 November, today'), findsOneWidget);
    expect(find.textContaining('3 days in November missed a daily goal'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('2 November, gym, missed water, protein'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('Mon, 2 November'), findsOneWidget);
    expect(find.text('Gym day'), findsOneWidget);
    expect(find.text('1 of 3 goals met'), findsOneWidget);
    expect(find.text('OK'), findsNothing);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Mon, 2 November'), findsNothing);

    expect(find.text('5K Club'), findsOneWidget);
  });

  testWidgets('goals: type a target, step it, add it', (tester) async {
    final root = GlobalKey<NavigatorState>();
    await pumpFeature(
      tester,
      routes: [
        GoRoute(path: '/', builder: (c, s) => const SizedBox()),
        ShellRoute(
          builder: (c, s, child) => Scaffold(body: child),
          routes: [ProgressRoutes.tab(root)],
        ),
      ],
      initial: ProgressRoutes.goals,
      height: 6000,
      navigatorKey: root,
      overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 5))],
    );
    expect(find.text('No weekly goals yet'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase target'));
    await tester.pump();
    expect(find.text('21'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '12.5');
    await tester.tap(find.byTooltip('Increase target'));
    await tester.pump();
    expect(find.text('13'), findsOneWidget);
    await tester.tap(find.text('Active burn'));
    await tester.pump();
    await tester.tap(find.byTooltip('Decrease target'));
    await tester.pump();
    expect(find.text('2950'), findsOneWidget);
    await tester.tap(find.text('Per week'));
    await tester.tap(find.text('Add goal'));
    await settleWithIo(tester, rounds: 10);
    expect(find.text('Burn 2950 kcal'), findsOneWidget);
    expect(find.text('0 of 2950 kcal'), findsOneWidget);
  });
}
