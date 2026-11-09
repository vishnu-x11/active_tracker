import '../../../../core/result.dart';
import '../entities/auth_rules.dart';
import '../repositories/auth_repository.dart';

class SendPasswordReset {
  const SendPasswordReset(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call(String email) async {
    final problem = AuthRules.email(email);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.sendPasswordReset(email.trim());
  }
}
