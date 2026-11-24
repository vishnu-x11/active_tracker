import 'package:go_router/go_router.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/reset_password_screen.dart';
import 'presentation/screens/sign_up_screen.dart';

abstract final class AuthRoutes {
  static const login = '/login';
  static const signUp = '/login/signup';
  static const reset = '/login/reset';

  static const loginAfterSignUp = '/login?registered=1';

  static bool isAuthRoute(String location) => location == login || location.startsWith('$login/');

  static final routes = <RouteBase>[
    GoRoute(
      path: login,
      builder: (context, state) => LoginScreen(registered: state.uri.queryParameters['registered'] == '1'),
      routes: [
        GoRoute(path: 'signup', builder: (context, state) => const SignUpScreen()),
        GoRoute(path: 'reset', builder: (context, state) => const ResetPasswordScreen()),
      ],
    ),
  ];
}
