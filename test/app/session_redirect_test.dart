import 'package:active_tracker/app/session_redirect.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const profile = Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600);

  test('status from the user id and profile', () {
    expect(sessionStatus(uid: const AsyncLoading(), profile: const AsyncLoading()), SessionStatus.loading);
    expect(sessionStatus(uid: const AsyncData(null), profile: const AsyncData(null)), SessionStatus.signedOut);
    expect(
      sessionStatus(uid: const AsyncError('x', StackTrace.empty), profile: const AsyncLoading()),
      SessionStatus.signedOut,
    );
    expect(sessionStatus(uid: const AsyncData('u1'), profile: const AsyncLoading()), SessionStatus.loading);
    expect(sessionStatus(uid: const AsyncData('u1'), profile: const AsyncData(null)), SessionStatus.needsProfile);
    expect(sessionStatus(uid: const AsyncData('u1'), profile: const AsyncData(profile)), SessionStatus.ready);
    expect(
      sessionStatus(uid: const AsyncData('u1'), profile: const AsyncError('x', StackTrace.empty)),
      SessionStatus.profileError,
    );
  });

  test('redirects', () {
    final cases = <(SessionStatus, String, String?)>[
      (SessionStatus.loading, '/home', '/splash'),
      (SessionStatus.loading, '/splash', null),
      (SessionStatus.signedOut, '/home', '/login'),
      (SessionStatus.signedOut, '/splash', '/login'),
      (SessionStatus.signedOut, '/login/phone/code', null),
      (SessionStatus.signedOut, '/onboarding', '/login'),
      (SessionStatus.needsProfile, '/login', '/onboarding'),
      (SessionStatus.needsProfile, '/onboarding/target', null),
      (SessionStatus.needsProfile, '/home', '/onboarding'),
      (SessionStatus.ready, '/login/phone', '/home'),
      (SessionStatus.ready, '/onboarding/target', '/home'),
      (SessionStatus.ready, '/splash', '/home'),
      (SessionStatus.ready, '/progress', null),
      (SessionStatus.profileError, '/home', '/splash'),
    ];
    for (final (status, from, to) in cases) {
      expect(sessionRedirect(status, from), to, reason: '$status at $from');
    }
  });
}
