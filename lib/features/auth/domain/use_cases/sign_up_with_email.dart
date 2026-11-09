import '../../../../core/result.dart';
import '../entities/auth_rules.dart';
import '../repositories/auth_repository.dart';

class SignUpWithEmail {
  const SignUpWithEmail(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String name, required String email, required String password}) async {
    final problem = AuthRules.name(name) ?? AuthRules.email(email) ?? AuthRules.newPassword(password);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.signUpWithEmail(name: name.trim(), email: email.trim(), password: password);
  }
}
