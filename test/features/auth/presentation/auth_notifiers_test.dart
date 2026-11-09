import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/domain/entities/auth_user.dart';
import 'package:active_tracker/features/auth/domain/entities/phone_verification.dart';
import 'package:active_tracker/features/auth/presentation/notifiers/login_notifier.dart';
import 'package:active_tracker/features/auth/presentation/notifiers/phone_auth_notifier.dart';
import 'package:active_tracker/features/auth/presentation/notifiers/sign_up_notifier.dart';
import 'package:active_tracker/features/auth/presentation/providers.dart';
import 'package:active_tracker/features/auth/presentation/states/login_state.dart';
import 'package:fake_async/fake_async.dart';
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

  group('phone', () {
    test('send → code screen state, countdown, then resend with the token', () {
      fakeAsync((async) {
        final sub = container.listen(phoneAuthProvider, (_, _) {});
        final n = container.read(phoneAuthProvider.notifier)..setNumber('98765 43210');
        n.sendCode();
        async.flushMicrotasks();
        expect(sub.read().sends, 1);
        expect(sub.read().verificationId, 'vid-1');
        expect(sub.read().secondsLeft, 30);
        expect(sub.read().canResend, isFalse);

        async.elapse(const Duration(seconds: 30));
        expect(sub.read().secondsLeft, 0);
        expect(sub.read().canResend, isTrue);

        n.resend();
        async.flushMicrotasks();
        expect(repo.calls.last, 'sendCode +919876543210 7');
        expect(sub.read().sends, 2);
      });
    });

    test('auto-verified on Android: no code screen', () async {
      repo.phoneResult = const Ok(PhoneAutoVerified(AuthUser(uid: 'p1')));
      final sub = container.listen(phoneAuthProvider, (_, _) {});
      await (container.read(phoneAuthProvider.notifier)..setNumber('9876543210')).sendCode();
      expect(sub.read().sends, 0);
      expect(sub.read().busy, isFalse);
    });

    test('a wrong code shows the message', () async {
      repo.verifyResult = const Err(AuthFailure('That code is wrong. Check the SMS and try again.'));
      final sub = container.listen(phoneAuthProvider, (_, _) {});
      final n = container.read(phoneAuthProvider.notifier)..setNumber('9876543210');
      await n.sendCode();
      n.setCode('123456');
      await n.verify();
      expect(sub.read().error, 'That code is wrong. Check the SMS and try again.');
    });
  });
}
