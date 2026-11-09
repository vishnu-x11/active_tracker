import '../../../../core/result.dart';
import '../entities/phone_verification.dart';
import '../repositories/auth_repository.dart';

class ResendPhoneCode {
  const ResendPhoneCode(this._repository);

  final AuthRepository _repository;

  static const wait = Duration(seconds: 30);

  Future<Result<PhoneVerification>> call({required String phoneE164, int? resendToken}) =>
      _repository.sendPhoneCode(phoneE164, resendToken: resendToken);
}
