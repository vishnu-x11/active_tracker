import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../providers.dart';
import '../states/login_state.dart';

final loginProvider = NotifierProvider.autoDispose<LoginNotifier, LoginState>(LoginNotifier.new);

class LoginNotifier extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginState();

  void setEmail(String v) => state = state.copyWith(email: v, error: () => null);
  void setPassword(String v) => state = state.copyWith(password: v, error: () => null);

  Future<void> signIn() async {
    if (state.isBusy) return;
    state = state.copyWith(showErrors: true, busy: LoginBusy.email, error: () => null);
    final result = await ref.read(signInWithEmailProvider)(email: state.email, password: state.password);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(busy: LoginBusy.none),
      Err(failure: ValidationFailure()) => state.copyWith(busy: LoginBusy.none),
      Err(:final failure) => state.copyWith(busy: LoginBusy.none, error: () => failure.message),
    };
  }

  Future<void> signInWithGoogle() async {
    if (state.isBusy) return;
    state = state.copyWith(busy: LoginBusy.google, error: () => null);
    final result = await ref.read(signInWithGoogleProvider)();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(busy: LoginBusy.none),
      Err(:final failure) => state.copyWith(busy: LoginBusy.none, error: () => failure.message),
    };
  }
}
