import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/result.dart';
import '../../domain/entities/profile.dart';
import '../providers.dart';
import '../states/onboarding_state.dart';
import 'profile_notifier.dart';

final onboardingProvider = NotifierProvider.autoDispose<OnboardingNotifier, OnboardingState>(OnboardingNotifier.new);

class OnboardingNotifier extends Notifier<OnboardingState> {
  @override
  OnboardingState build() {
    ref.listen(currentUidProvider, (_, _) {});
    return const OnboardingState();
  }

  void setWeight(String v) => state = state.copyWith(weight: v);
  void setHeight(String v) => state = state.copyWith(height: v);
  void setAge(String v) => state = state.copyWith(age: v);
  void setSex(Sex? v) => state = state.copyWith(sex: () => v);
  void setBurnTarget(String v) => state = state.copyWith(burnTarget: v, error: () => null);

  bool continueToTarget() {
    state = state.copyWith(showBodyErrors: true);
    return state.bodyValid;
  }

  Future<void> finish() async {
    if (state.saving) return;
    state = state.copyWith(showBurnError: true, saving: true, error: () => null);
    final uid = await ref.read(currentUidProvider.future);
    if (!ref.mounted) return;
    if (uid == null) {
      state = state.copyWith(saving: false, error: () => 'You are signed out. Sign in again.');
      return;
    }
    final result = await ref.read(saveBodyStatsProvider)(
      uid: uid,
      weight: state.weight,
      height: state.height,
      age: state.age,
      sex: state.sex,
      burnTarget: state.burnTarget,
    );
    if (!ref.mounted) return;
    switch (result) {
      case Ok(:final value):
        state = state.copyWith(saving: false);
        ref.read(profileProvider.notifier).saved(value);
      case Err(failure: ValidationFailure()):
        state = state.copyWith(saving: false);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
    }
  }
}
