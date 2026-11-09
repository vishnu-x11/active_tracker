import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'presentation/screens/onboarding_body_screen.dart';
import 'presentation/screens/onboarding_target_screen.dart';
import 'presentation/screens/profile_screen.dart';

export 'presentation/screens/profile_screen.dart' show ProfileAccountRow;

abstract final class ProfileRoutes {
  static const onboarding = '/onboarding';
  static const target = '/onboarding/target';
  static const profile = '/profile';

  static GoRoute tab({List<Widget> accountRows = const []}) => GoRoute(
    path: profile,
    builder: (context, state) => ProfileScreen(accountRows: accountRows),
  );

  static bool isOnboarding(String location) => location == onboarding || location.startsWith('$onboarding/');

  static List<RouteBase> routes({Widget? onboardingAction}) => [
    GoRoute(
      path: onboarding,
      builder: (context, state) => OnboardingBodyScreen(action: onboardingAction),
      routes: [GoRoute(path: 'target', builder: (context, state) => const OnboardingTargetScreen())],
    ),
  ];
}
