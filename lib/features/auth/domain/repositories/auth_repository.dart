import '../../../../core/result.dart';
import '../entities/auth_user.dart';
import '../entities/phone_verification.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password});

  Future<Result<void>> signUpWithEmail({required String name, required String email, required String password});

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<AuthUser?>> signInWithGoogle();

  Future<Result<PhoneVerification>> sendPhoneCode(String phoneE164, {int? resendToken});

  Future<Result<AuthUser>> verifyPhoneCode({required String verificationId, required String smsCode});

  Future<Result<void>> signOut();
}
