import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:active_tracker/features/auth/domain/entities/phone_verification.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneCodeSent;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeAuthRemoteDataSource remote;
  late AuthRepositoryImpl repo;
  setUp(() {
    remote = FakeAuthRemoteDataSource();
    repo = AuthRepositoryImpl(remote);
  });

  Future<String?> failureOf(Future<Result<Object?>> call) async => switch (await call) {
    Err(:final failure) => failure.message,
    Ok() => null,
  };

  test('Firebase error codes become readable failures', () async {
    final cases = {
      'invalid-credential': 'Wrong email or password.',
      'email-already-in-use': 'This email is already registered. Sign in instead.',
      'invalid-verification-code': 'That code is wrong. Check the SMS and try again.',
      'session-expired': 'The code has expired. Send a new one.',
      'too-many-requests': 'Too many attempts. Wait a few minutes and try again.',
      'network-request-failed': 'No internet connection. Check it and try again.',
      'something-new': 'Sign-in failed. Please try again.',
    };
    for (final MapEntry(key: code, value: text) in cases.entries) {
      remote.error = FirebaseAuthException(code: code);
      expect(await failureOf(repo.sendPasswordReset('a@b.co')), text, reason: code);
    }
  });

  test('every failure is an AuthFailure; nothing throws', () async {
    remote.error = StateError('boom');
    final r = await repo.signOut();
    expect((r as Err).failure, isA<AuthFailure>());
    expect(r.failure.message, 'Something went wrong. Please try again.');
  });

  test('closing the Google picker is Ok(null), not an error', () async {
    expect((await repo.signInWithGoogle()).valueOrNull, isNull);
    remote.error = PlatformException(code: 'sign_in_canceled');
    expect(await repo.signInWithGoogle(), isA<Ok<Object?>>());
  });

  test('Google config errors point at the SHA-1', () async {
    remote.error = PlatformException(code: 'sign_in_failed', message: 'ApiException: 10: ');
    expect(
      await failureOf(repo.signInWithGoogle()),
      'Google sign-in is not set up for this build (SHA-1 missing in Firebase).',
    );
  });

  test('a sent code passes through', () async {
    remote.phone = const PhoneCodeSent(verificationId: 'abc', resendToken: 3);
    final r = await repo.sendPhoneCode('+919876543210');
    expect(r.valueOrNull, isA<PhoneCodeSent>().having((c) => c.verificationId, 'id', 'abc'));
  });
}
