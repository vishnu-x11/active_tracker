import '../../domain/entities/auth_rules.dart';

class PhoneAuthState {
  const PhoneAuthState({
    this.countryCode = '+91',
    this.number = '',
    this.code = '',
    this.showErrors = false,
    this.busy = false,
    this.error,
    this.phoneE164,
    this.verificationId,
    this.resendToken,
    this.secondsLeft = 0,
    this.sends = 0,
  });

  final String countryCode;
  final String number;
  final String code;
  final bool showErrors;
  final bool busy;
  final String? error;

  final String? phoneE164;
  final String? verificationId;
  final int? resendToken;

  final int secondsLeft;

  final int sends;

  String? get numberError => showErrors ? (AuthRules.countryCode(countryCode) ?? AuthRules.phoneNumber(number)) : null;
  bool get canResend => secondsLeft == 0 && !busy && phoneE164 != null;

  PhoneAuthState copyWith({
    String? countryCode,
    String? number,
    String? code,
    bool? showErrors,
    bool? busy,
    String? Function()? error,
    String? phoneE164,
    String? verificationId,
    int? Function()? resendToken,
    int? secondsLeft,
    int? sends,
  }) => PhoneAuthState(
    countryCode: countryCode ?? this.countryCode,
    number: number ?? this.number,
    code: code ?? this.code,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
    phoneE164: phoneE164 ?? this.phoneE164,
    verificationId: verificationId ?? this.verificationId,
    resendToken: resendToken != null ? resendToken() : this.resendToken,
    secondsLeft: secondsLeft ?? this.secondsLeft,
    sends: sends ?? this.sends,
  );

  @override
  bool operator ==(Object other) =>
      other is PhoneAuthState &&
      other.countryCode == countryCode &&
      other.number == number &&
      other.code == code &&
      other.showErrors == showErrors &&
      other.busy == busy &&
      other.error == error &&
      other.phoneE164 == phoneE164 &&
      other.verificationId == verificationId &&
      other.resendToken == resendToken &&
      other.secondsLeft == secondsLeft &&
      other.sends == sends;

  @override
  int get hashCode => Object.hash(
    countryCode,
    number,
    code,
    showErrors,
    busy,
    error,
    phoneE164,
    verificationId,
    resendToken,
    secondsLeft,
    sends,
  );
}
