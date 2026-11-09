import 'package:go_router/go_router.dart';

import 'presentation/screens/hydration_history_screen.dart';
import 'presentation/screens/hydration_screen.dart';

abstract final class HydrationRoutes {
  static const water = '/water';
  static const history = '/water/history';

  static final routes = <RouteBase>[
    GoRoute(
      path: water,
      builder: (context, state) => const HydrationScreen(),
      routes: [GoRoute(path: 'history', builder: (context, state) => const HydrationHistoryScreen())],
    ),
  ];
}
