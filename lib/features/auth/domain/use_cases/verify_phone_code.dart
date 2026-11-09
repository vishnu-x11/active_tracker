import '../../../../core/result.dart';
import '../entities/auth_rules.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class VerifyPhoneCode {
  const VerifyPhoneCode(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser>> call({required String verificationId, required String smsCode}) async {
    final problem = AuthRules.smsCode(smsCode);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.verifyPhoneCode(verificationId: verificationId, smsCode: smsCode);
  }
}
