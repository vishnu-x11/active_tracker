import 'auth_user.dart';

sealed class PhoneVerification {
  const PhoneVerification();
}

final class PhoneCodeSent extends PhoneVerification {
  const PhoneCodeSent({required this.verificationId, this.resendToken});

  final String verificationId;
  final int? resendToken;
}

final class PhoneAutoVerified extends PhoneVerification {
  const PhoneAutoVerified(this.user);

  final AuthUser user;
}
