import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/auth_routes.dart';
import '../features/profile/domain/entities/profile.dart';
import '../features/profile/profile_routes.dart';

enum SessionStatus { loading, signedOut, needsProfile, ready, profileError }

abstract final class AppRoutes {
  static const splash = '/splash';
  static const home = '/home';
  static const log = '/log';
}

SessionStatus sessionStatus({required AsyncValue<String?> uid, required AsyncValue<Profile?> profile}) {
  if (uid.hasError) return SessionStatus.signedOut;
  if (!uid.hasValue) return SessionStatus.loading;
  if (uid.value == null) return SessionStatus.signedOut;
  if (profile.isLoading) return SessionStatus.loading;
  if (profile.hasError) return SessionStatus.profileError;
  return profile.value == null ? SessionStatus.needsProfile : SessionStatus.ready;
}

String? sessionRedirect(SessionStatus status, String location) {
  String? goTo(String target) => location == target ? null : target;
  return switch (status) {
    SessionStatus.loading || SessionStatus.profileError => goTo(AppRoutes.splash),
    SessionStatus.signedOut => AuthRoutes.isAuthRoute(location) ? null : AuthRoutes.login,
    SessionStatus.needsProfile => ProfileRoutes.isOnboarding(location) ? null : ProfileRoutes.onboarding,
    SessionStatus.ready =>
      AuthRoutes.isAuthRoute(location) || ProfileRoutes.isOnboarding(location) || location == AppRoutes.splash
          ? AppRoutes.home
          : null,
  };
}
