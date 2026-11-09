import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../providers.dart';
import '../states/sign_up_state.dart';

final signUpProvider = NotifierProvider.autoDispose<SignUpNotifier, SignUpState>(SignUpNotifier.new);

class SignUpNotifier extends Notifier<SignUpState> {
  @override
  SignUpState build() => const SignUpState();

  void setName(String v) => state = state.copyWith(name: v, error: () => null);
  void setEmail(String v) => state = state.copyWith(email: v, error: () => null);
  void setPassword(String v) => state = state.copyWith(password: v, error: () => null);

  Future<void> submit() async {
    if (state.busy) return;
    state = state.copyWith(showErrors: true, busy: true, error: () => null);
    final result = await ref.read(signUpWithEmailProvider)(
      name: state.name,
      email: state.email,
      password: state.password,
    );
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(busy: false, done: true),
      Err(failure: ValidationFailure()) => state.copyWith(busy: false),
      Err(:final failure) => state.copyWith(busy: false, error: () => failure.message),
    };
  }
}
