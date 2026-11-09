import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../../../core/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/phone_verification.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_sources/auth_remote_data_source.dart';
import '../models/auth_user_mapper.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) =>
      _guard(() async => (await _remote.signInWithEmail(email, password)).toEntity());

  @override
  Future<Result<void>> signUpWithEmail({required String name, required String email, required String password}) =>
      _guard(() => _remote.createAccount(name: name, email: email, password: password));

  @override
  Future<Result<void>> sendPasswordReset(String email) => _guard(() => _remote.sendPasswordReset(email));

  @override
  Future<Result<AuthUser?>> signInWithGoogle() async {
    try {
      return Ok((await _remote.signInWithGoogle())?.toEntity());
    } on PlatformException catch (e) {
      if (e.code == 'sign_in_canceled') return const Ok(null);
      return Err(AuthFailure(googleMessage(e), e));
    } catch (e) {
      return Err(_failure(e));
    }
  }

  @override
  Future<Result<PhoneVerification>> sendPhoneCode(String phoneE164, {int? resendToken}) =>
      _guard(() => _remote.sendPhoneCode(phoneE164, resendToken: resendToken));

  @override
  Future<Result<AuthUser>> verifyPhoneCode({required String verificationId, required String smsCode}) =>
      _guard(() async => (await _remote.verifyPhoneCode(verificationId, smsCode)).toEntity());

  @override
  Future<Result<void>> signOut() => _guard(_remote.signOut);

  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Ok(await call());
    } catch (e) {
      return Err(_failure(e));
    }
  }

  AuthFailure _failure(Object e) => switch (e) {
    FirebaseAuthException() => AuthFailure(firebaseMessage(e.code), e),
    PlatformException() => AuthFailure(googleMessage(e), e),
    _ => AuthFailure('Something went wrong. Please try again.', e),
  };

  static String firebaseMessage(String code) => switch (code) {
    'invalid-credential' || 'wrong-password' || 'INVALID_LOGIN_CREDENTIALS' => 'Wrong email or password.',
    'user-not-found' => 'No account with this email. Create one first.',
    'invalid-email' => 'Enter a valid email address.',
    'user-disabled' => 'This account has been disabled.',
    'email-already-in-use' => 'This email is already registered. Sign in instead.',
    'weak-password' => 'Choose a stronger password (at least 6 characters).',
    'account-exists-with-different-credential' => 'This email already signs in another way. Try email or Google.',
    'invalid-phone-number' => 'That phone number is not valid.',
    'invalid-verification-code' => 'That code is wrong. Check the SMS and try again.',
    'session-expired' || 'code-expired' => 'The code has expired. Send a new one.',
    'quota-exceeded' => 'SMS limit reached. Try again later.',
    'missing-client-identifier' ||
    'app-not-authorized' ||
    'invalid-app-credential' => 'Phone sign-in is not set up for this build yet.',
    'operation-not-allowed' => 'This sign-in method is turned off.',
    'too-many-requests' => 'Too many attempts. Wait a few minutes and try again.',
    'network-request-failed' => 'No internet connection. Check it and try again.',
    _ => 'Sign-in failed. Please try again.',
  };

  static String googleMessage(PlatformException e) {
    final detail = '${e.code} ${e.message}';
    if (e.code == 'network_error') return 'No internet connection. Check it and try again.';
    if (RegExp(r'\b(10|12500|28444)\b').hasMatch(detail) || detail.contains('developer console')) {
      return 'Google sign-in is not set up for this build (SHA-1 missing in Firebase).';
    }
    return 'Google sign-in failed. Please try again.';
  }
}
