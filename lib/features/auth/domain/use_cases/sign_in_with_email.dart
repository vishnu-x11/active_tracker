import '../../../../core/result.dart';
import '../entities/auth_rules.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class SignInWithEmail {
  const SignInWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({required String email, required String password}) async {
    final problem = AuthRules.email(email) ?? AuthRules.password(password);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.signInWithEmail(email: email.trim(), password: password);
  }
}
