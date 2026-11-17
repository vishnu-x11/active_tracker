import '../../../../core/result.dart';
import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  Future<Result<AuthUser>> signInWithEmail({required String email, required String password});

  Future<Result<void>> signUpWithEmail({required String name, required String email, required String password});

  Future<Result<void>> sendPasswordReset(String email);

  Future<Result<AuthUser?>> signInWithGoogle();

  Future<Result<void>> signOut();
}
