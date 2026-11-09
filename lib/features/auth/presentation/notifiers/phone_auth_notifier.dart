import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../domain/entities/auth_rules.dart';
import '../../domain/entities/phone_verification.dart';
import '../../domain/use_cases/resend_phone_code.dart';
import '../providers.dart';
import '../states/phone_auth_state.dart';

final phoneAuthProvider = NotifierProvider.autoDispose<PhoneAuthNotifier, PhoneAuthState>(PhoneAuthNotifier.new);

class PhoneAuthNotifier extends Notifier<PhoneAuthState> {
  Timer? _countdown;

  @override
  PhoneAuthState build() {
    ref.onDispose(() => _countdown?.cancel());
    return const PhoneAuthState();
  }

  void setCountryCode(String v) => state = state.copyWith(countryCode: v, error: () => null);
  void setNumber(String v) => state = state.copyWith(number: v, error: () => null);
  void setCode(String v) => state = state.copyWith(code: v, error: () => null);

  Future<void> sendCode() async {
    if (state.busy) return;
    state = state.copyWith(showErrors: true, busy: true, error: () => null);
    final result = await ref.read(sendPhoneCodeProvider)(countryCode: state.countryCode, number: state.number);
    if (!ref.mounted) return;
    _apply(result, phoneE164: AuthRules.e164(state.countryCode, state.number));
  }

  Future<void> resend() async {
    if (!state.canResend) return;
    state = state.copyWith(busy: true, error: () => null, code: '');
    final result = await ref.read(resendPhoneCodeProvider)(phoneE164: state.phoneE164!, resendToken: state.resendToken);
    if (!ref.mounted) return;
    _apply(result, phoneE164: state.phoneE164!);
  }

  Future<void> verify() async {
    final id = state.verificationId;
    if (state.busy || id == null) return;
    state = state.copyWith(busy: true, error: () => null);
    final result = await ref.read(verifyPhoneCodeProvider)(verificationId: id, smsCode: state.code);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(busy: false),
      Err(:final failure) => state.copyWith(busy: false, error: () => failure.message),
    };
  }

  void _apply(Result<PhoneVerification> result, {required String phoneE164}) {
    switch (result) {
      case Ok(value: PhoneCodeSent(:final verificationId, :final resendToken)):
        state = state.copyWith(
          busy: false,
          phoneE164: phoneE164,
          verificationId: verificationId,
          resendToken: () => resendToken,
          sends: state.sends + 1,
        );
        _startCountdown();
      case Ok(value: PhoneAutoVerified()):
        state = state.copyWith(busy: false);
      case Err(failure: ValidationFailure()):
        state = state.copyWith(busy: false);
      case Err(:final failure):
        state = state.copyWith(busy: false, error: () => failure.message);
    }
  }

  void _startCountdown() {
    _countdown?.cancel();
    state = state.copyWith(secondsLeft: ResendPhoneCode.wait.inSeconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (t) {
      final left = state.secondsLeft - 1;
      state = state.copyWith(secondsLeft: left < 0 ? 0 : left);
      if (left <= 0) t.cancel();
    });
  }
}
