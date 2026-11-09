import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/features/activity/activity_routes.dart';
import 'package:active_tracker/features/gym/gym_routes.dart';
import 'package:active_tracker/features/home/home_routes.dart';
import 'package:active_tracker/features/hydration/hydration_routes.dart';
import 'package:active_tracker/features/progress/progress_routes.dart';
import 'package:active_tracker/features/protein/protein_routes.dart';
import 'package:active_tracker/features/profile/profile_routes.dart';
import 'package:active_tracker/features/reminders/reminders_routes.dart';
import 'package:active_tracker/features/running/running_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../helpers/app_harness.dart';
import '../helpers/pump.dart';
import '../helpers/seed.dart';

void main() {
  final root = GlobalKey<NavigatorState>();
  final screens = <String, (String, List<RouteBase>)>{
    'home': (HomeRoutes.home, [HomeRoutes.route]),
    'activity': (ActivityRoutes.activity, [ActivityRoutes.route]),
    'progress': (ProgressRoutes.progress, [ProgressRoutes.tab(root)]),
    'profile': (ProfileRoutes.profile, [ProfileRoutes.tab()]),
    'hydration': (HydrationRoutes.water, HydrationRoutes.routes),
    'protein': (ProteinRoutes.protein, [ProteinRoutes.route]),
    'gym log': (GymRoutes.newSession, GymRoutes.routes),
    'run log': (RunRoutes.newRun, RunRoutes.routes()),
    'reminders': (ReminderRoutes.reminders, [ReminderRoutes.route]),
    'goals': (ProgressRoutes.goals, [ProgressRoutes.tab(root)]),
    'weekly report': (ProgressRoutes.week, [ProgressRoutes.tab(root)]),
    'streaks': (ProgressRoutes.streaks, [ProgressRoutes.tab(root)]),
    'hydration history': (HydrationRoutes.history, HydrationRoutes.routes),
    'muscle recovery': (GymRoutes.recovery, GymRoutes.routes),
  };

  for (final MapEntry(key: name, value: (path, routes)) in screens.entries) {
    testWidgets('$name fits a small phone with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.3;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpFeature(
        tester,
        routes: [
          ShellRoute(
            builder: (c, s, child) => Scaffold(body: child),
            routes: routes,
          ),
        ],
        initial: path,
        navigatorKey: root,
        height: 5000,
        width: 320,
        overrides: [todayProvider.overrideWithValue(DateTime(2026, 11, 5))],
        seed: (db) async {
          final s = Seed(db);
          await s.gym(DateTime(2026, 11, 5, 18, 30), kcal: 712, title: 'Shoulders + Triceps + Chest');
          await s.run(DateTime(2026, 11, 5, 6, 45), kcal: 405);
          await s.water(DateTime(2026, 11, 5, 9), 1750);
          await s.protein(DateTime(2026, 11, 5, 13), 86);
        },
      );
      await settleWithIo(tester, rounds: 8);
      expect(tester.takeException(), isNull);
    });
  }
}
