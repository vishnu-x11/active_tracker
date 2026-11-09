import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../providers.dart';
import '../states/reset_state.dart';

final resetProvider = NotifierProvider.autoDispose<ResetNotifier, ResetState>(ResetNotifier.new);

class ResetNotifier extends Notifier<ResetState> {
  @override
  ResetState build() => const ResetState();

  void setEmail(String v) => state = state.copyWith(email: v, error: () => null);

  Future<void> send() async {
    if (state.busy) return;
    state = state.copyWith(showErrors: true, busy: true, error: () => null, sentTo: () => null);
    final result = await ref.read(sendPasswordResetProvider)(state.email);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => state.copyWith(busy: false, sentTo: () => state.email.trim()),
      Err(failure: ValidationFailure()) => state.copyWith(busy: false),
      Err(:final failure) => state.copyWith(busy: false, error: () => failure.message),
    };
  }
}
