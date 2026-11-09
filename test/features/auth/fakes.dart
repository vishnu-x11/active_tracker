import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/data/data_sources/auth_remote_data_source.dart';
import 'package:active_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:active_tracker/features/auth/domain/entities/phone_verification.dart';
import 'package:active_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:firebase_auth/firebase_auth.dart' hide PhoneCodeSent;

class FakeAuthRepository implements AuthRepository {
  final calls = <String>[];

  Result<AuthUser> signInResult = const Ok(AuthUser(uid: 'u1', email: 'a@b.co'));
  Result<void> signUpResult = const Ok(null);
  Result<void> resetResult = const Ok(null);
  Result<AuthUser?> googleResult = const Ok(AuthUser(uid: 'g1'));
  Result<PhoneVerification> phoneResult = const Ok(PhoneCodeSent(verificationId: 'vid-1', resendToken: 7));
  Result<AuthUser> verifyResult = const Ok(AuthUser(uid: 'p1', phoneNumber: '+919876543210'));
  Result<void> signOutResult = const Ok(null);

  @override
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password}) async {
    calls.add('signIn $email');
    return signInResult;
  }

  @override
  Future<Result<void>> signUpWithEmail({required String name, required String email, required String password}) async {
    calls.add('signUp $name $email');
    return signUpResult;
  }

  @override
  Future<Result<void>> sendPasswordReset(String email) async {
    calls.add('reset $email');
    return resetResult;
  }

  @override
  Future<Result<AuthUser?>> signInWithGoogle() async {
    calls.add('google');
    return googleResult;
  }

  @override
  Future<Result<PhoneVerification>> sendPhoneCode(String phoneE164, {int? resendToken}) async {
    calls.add('sendCode $phoneE164 ${resendToken ?? '-'}');
    return phoneResult;
  }

  @override
  Future<Result<AuthUser>> verifyPhoneCode({required String verificationId, required String smsCode}) async {
    calls.add('verify $verificationId $smsCode');
    return verifyResult;
  }

  @override
  Future<Result<void>> signOut() async {
    calls.add('signOut');
    return signOutResult;
  }
}

class FakeAuthRemoteDataSource implements AuthRemoteDataSource {
  Object? error;
  User? googleUser;
  PhoneVerification phone = const PhoneCodeSent(verificationId: 'vid');

  Future<T> _answer<T>(T value) async {
    if (error != null) throw error!;
    return value;
  }

  @override
  Future<User> signInWithEmail(String email, String password) => _answer<User>(throw UnimplementedError());

  @override
  Future<void> createAccount({required String name, required String email, required String password}) => _answer(null);

  @override
  Future<void> sendPasswordReset(String email) => _answer(null);

  @override
  Future<User?> signInWithGoogle() => _answer(googleUser);

  @override
  Future<PhoneVerification> sendPhoneCode(String phoneE164, {int? resendToken}) => _answer(phone);

  @override
  Future<User> verifyPhoneCode(String verificationId, String smsCode) => _answer<User>(throw UnimplementedError());

  @override
  Future<void> signOut() => _answer(null);
}
