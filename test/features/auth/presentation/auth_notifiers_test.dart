import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/presentation/notifiers/login_notifier.dart';
import 'package:active_tracker/features/auth/presentation/notifiers/sign_up_notifier.dart';
import 'package:active_tracker/features/auth/presentation/providers.dart';
import 'package:active_tracker/features/auth/presentation/states/login_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeAuthRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = FakeAuthRepository();
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repo)]);
  });
  tearDown(() => container.dispose());

  group('login', () {
    test('bad input shows field errors and no banner', () async {
      final sub = container.listen(loginProvider, (_, _) {});
      await container.read(loginProvider.notifier).signIn();
      final s = sub.read();
      expect(s.emailError, 'Enter your email');
      expect(s.passwordError, 'Enter your password');
      expect(s.error, isNull);
      expect(repo.calls, isEmpty);
    });

    test('a failed request shows its message and clears when typing', () async {
      repo.signInResult = const Err(AuthFailure('Wrong email or password.'));
      final sub = container.listen(loginProvider, (_, _) {});
      final n = container.read(loginProvider.notifier)
        ..setEmail('a@b.co')
        ..setPassword('secret');
      await n.signIn();
      expect(sub.read().error, 'Wrong email or password.');
      expect(sub.read().busy, LoginBusy.none);
      n.setPassword('secret2');
      expect(sub.read().error, isNull);
    });

    test('cancelled Google sign-in is silent', () async {
      repo.googleResult = const Ok(null);
      final sub = container.listen(loginProvider, (_, _) {});
      await container.read(loginProvider.notifier).signInWithGoogle();
      expect(sub.read().error, isNull);
      expect(repo.calls, ['google']);
    });
  });

  test('sign-up marks done so the screen returns to login', () async {
    final sub = container.listen(signUpProvider, (_, _) {});
    container.read(signUpProvider.notifier)
      ..setName('Asha')
      ..setEmail('a@b.co')
      ..setPassword('secret1');
    await container.read(signUpProvider.notifier).submit();
    expect(sub.read().done, isTrue);
  });
}
