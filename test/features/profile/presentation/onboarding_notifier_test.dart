import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/profile/presentation/notifiers/onboarding_notifier.dart';
import 'package:active_tracker/features/profile/presentation/notifiers/profile_notifier.dart';
import 'package:active_tracker/features/profile/presentation/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeProfileRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeProfileRepository();
    container = ProviderContainer(
      overrides: [
        profileRepositoryProvider.overrideWithValue(repo),
        currentUidProvider.overrideWith((ref) => Stream.value('u1')),
      ],
    );
  });
  tearDown(() => container.dispose());

  test('targets follow the typed weight and height', () {
    final sub = container.listen(onboardingProvider, (_, _) {});
    container.read(onboardingProvider.notifier)
      ..setWeight('75')
      ..setHeight('178');
    final s = sub.read();
    expect(s.bmiValue!.toStringAsFixed(1), '23.7');
    expect(s.proteinG, 120);
    expect(s.waterMl, 2625);
    expect(s.gymHourKcal, 375);
  });

  test('continue is blocked until weight and height are valid', () {
    final sub = container.listen(onboardingProvider, (_, _) {});
    final n = container.read(onboardingProvider.notifier);
    expect(n.continueToTarget(), isFalse);
    expect(sub.read().weightError, 'Enter your weight');
    n
      ..setWeight('75')
      ..setHeight('178');
    expect(n.continueToTarget(), isTrue);
  });

  test('finish saves with the 600 suggestion and fills profileProvider', () async {
    final profileSub = container.listen(profileProvider, (_, _) {});
    await container.read(profileProvider.future);
    expect(profileSub.read().value, isNull);

    final sub = container.listen(onboardingProvider, (_, _) {});
    final n = container.read(onboardingProvider.notifier)
      ..setWeight('75')
      ..setHeight('178');
    await n.finish();

    expect(sub.read().error, isNull);
    expect(repo.saved['u1']!.burnTargetKcal, 600);
    expect(profileSub.read().value, repo.saved['u1']);
  });

  test('a storage failure is shown and nothing changes', () async {
    repo.saveResult = const Err(StorageFailure("Couldn't save your profile. Please try again."));
    final sub = container.listen(onboardingProvider, (_, _) {});
    final n = container.read(onboardingProvider.notifier)
      ..setWeight('75')
      ..setHeight('178');
    await n.finish();
    expect(sub.read().error, "Couldn't save your profile. Please try again.");
    expect(sub.read().saving, isFalse);
  });
}
