import 'package:go_router/go_router.dart';

import 'presentation/screens/activity_screen.dart';

abstract final class ActivityRoutes {
  static const activity = '/activity';

  static final route = GoRoute(path: activity, builder: (context, state) => const ActivityScreen());
}
