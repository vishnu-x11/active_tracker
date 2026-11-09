import 'package:go_router/go_router.dart';

import 'presentation/screens/home_screen.dart';

abstract final class HomeRoutes {
  static const home = '/home';

  static final route = GoRoute(path: home, builder: (context, state) => const HomeScreen());
}
