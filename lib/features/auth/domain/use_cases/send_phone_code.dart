import '../../../../core/result.dart';
import '../entities/auth_rules.dart';
import '../entities/phone_verification.dart';
import '../repositories/auth_repository.dart';

class SendPhoneCode {
  const SendPhoneCode(this._repository);

  final AuthRepository _repository;

  Future<Result<PhoneVerification>> call({required String countryCode, required String number}) async {
    final problem = AuthRules.countryCode(countryCode) ?? AuthRules.phoneNumber(number);
    if (problem != null) return Err(ValidationFailure(problem));
    return _repository.sendPhoneCode(AuthRules.e164(countryCode, number));
  }
}
