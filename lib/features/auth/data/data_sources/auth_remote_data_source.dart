import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' hide PhoneCodeSent;
import 'package:google_sign_in/google_sign_in.dart';

import '../../domain/entities/phone_verification.dart';
import '../models/auth_user_mapper.dart';

abstract interface class AuthRemoteDataSource {
  Future<User> signInWithEmail(String email, String password);
  Future<void> createAccount({required String name, required String email, required String password});
  Future<void> sendPasswordReset(String email);

  Future<User?> signInWithGoogle();
  Future<PhoneVerification> sendPhoneCode(String phoneE164, {int? resendToken});
  Future<User> verifyPhoneCode(String verificationId, String smsCode);
  Future<void> signOut();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl(this._auth, this._google);

  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  static const googleServerClientId = '773988908810-g9edgsr32bj76ncpc545e0r29p54mfu5.apps.googleusercontent.com';

  User _require(UserCredential c) => c.user ?? (throw StateError('Firebase returned no user'));

  @override
  Future<User> signInWithEmail(String email, String password) async =>
      _require(await _auth.signInWithEmailAndPassword(email: email, password: password));

  @override
  Future<void> createAccount({required String name, required String email, required String password}) async {
    final user = _require(await _auth.createUserWithEmailAndPassword(email: email, password: password));
    await user.updateDisplayName(name);
    await _auth.signOut();
  }

  @override
  Future<void> sendPasswordReset(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<User?> signInWithGoogle() async {
    final account = await _google.signIn();
    if (account == null) return null;
    final tokens = await account.authentication;
    final credential = GoogleAuthProvider.credential(accessToken: tokens.accessToken, idToken: tokens.idToken);
    return _require(await _auth.signInWithCredential(credential));
  }

  @override
  Future<PhoneVerification> sendPhoneCode(String phoneE164, {int? resendToken}) {
    final result = Completer<PhoneVerification>();
    void fail(Object e, [StackTrace? st]) {
      if (!result.isCompleted) result.completeError(e, st);
    }

    _auth
        .verifyPhoneNumber(
          phoneNumber: phoneE164,
          forceResendingToken: resendToken,
          timeout: const Duration(seconds: 60),
          verificationCompleted: (credential) async {
            try {
              final user = _require(await _auth.signInWithCredential(credential));
              if (!result.isCompleted) result.complete(PhoneAutoVerified(user.toEntity()));
            } catch (e, st) {
              fail(e, st);
            }
          },
          verificationFailed: fail,
          codeSent: (verificationId, token) {
            if (!result.isCompleted) {
              result.complete(PhoneCodeSent(verificationId: verificationId, resendToken: token));
            }
          },
          codeAutoRetrievalTimeout: (_) {},
        )
        .catchError(fail);
    return result.future;
  }

  @override
  Future<User> verifyPhoneCode(String verificationId, String smsCode) async => _require(
    await _auth.signInWithCredential(PhoneAuthProvider.credential(verificationId: verificationId, smsCode: smsCode)),
  );

  @override
  Future<void> signOut() async {
    await _auth.signOut();
    await _google.signOut();
  }
}
