import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/goals_screen.dart';
import 'presentation/screens/progress_screen.dart';
import 'presentation/screens/streaks_screen.dart';
import 'presentation/screens/weekly_report_screen.dart';

abstract final class ProgressRoutes {
  static const progress = '/progress';
  static const week = '/progress/week';
  static const goals = '/progress/goals';
  static const streaks = '/progress/streaks';

  static GoRoute tab(GlobalKey<NavigatorState> root, {List<Widget> actions = const []}) => GoRoute(
    path: progress,
    builder: (context, state) => ProgressScreen(actions: actions),
    routes: [
      GoRoute(path: 'week', parentNavigatorKey: root, builder: (context, state) => const WeeklyReportScreen()),
      GoRoute(path: 'goals', parentNavigatorKey: root, builder: (context, state) => const GoalsScreen()),
      GoRoute(path: 'streaks', parentNavigatorKey: root, builder: (context, state) => const StreaksScreen()),
    ],
  );
}
