import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'domain/entities/goal.dart';
import 'presentation/screens/goals_screen.dart';
import 'presentation/screens/progress_screen.dart';
import 'presentation/screens/streaks_screen.dart';
import 'presentation/screens/training_log_screen.dart';
import 'presentation/screens/weekly_report_screen.dart';

abstract final class ProgressRoutes {
  static const progress = '/progress';
  static const week = '/progress/week';
  static const goals = '/progress/goals';
  static const streaks = '/progress/streaks';
  static const log = '/progress/log';

  static String goalsFor(GoalKind kind, GoalPeriod period, double target) =>
      Uri(path: goals, queryParameters: {'kind': kind.name, 'period': period.name, 'target': '$target'}).toString();

  static GoRoute tab(
    GlobalKey<NavigatorState> root, {
    List<Widget> actions = const [],
    List<Widget> insights = const [],
    String dayRoute = '/',
  }) => GoRoute(
    path: progress,
    builder: (context, state) => ProgressScreen(actions: actions, insights: insights),
    routes: [
      GoRoute(path: 'week', parentNavigatorKey: root, builder: (context, state) => const WeeklyReportScreen()),
      GoRoute(
        path: 'goals',
        parentNavigatorKey: root,
        builder: (context, state) {
          final q = state.uri.queryParameters;
          return GoalsScreen(
            initialKind: GoalKind.values.where((k) => k.name == q['kind']).firstOrNull,
            initialPeriod: GoalPeriod.values.where((k) => k.name == q['period']).firstOrNull,
            initialTarget: double.tryParse(q['target'] ?? ''),
          );
        },
      ),
      GoRoute(path: 'streaks', parentNavigatorKey: root, builder: (context, state) => const StreaksScreen()),
      GoRoute(
        path: 'log',
        parentNavigatorKey: root,
        builder: (context, state) => TrainingLogScreen(dayRoute: dayRoute),
      ),
    ],
  );
}
