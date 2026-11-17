import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/domain/entities/auth_rules.dart';
import 'package:active_tracker/features/auth/domain/use_cases/send_password_reset.dart';
import 'package:active_tracker/features/auth/domain/use_cases/sign_in_with_email.dart';
import 'package:active_tracker/features/auth/domain/use_cases/sign_up_with_email.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  late FakeAuthRepository repo;
  setUp(() => repo = FakeAuthRepository());

  String? message(Result<Object?> r) => r is Err<Object?> ? r.failure.message : null;

  group('AuthRules', () {
    test('email', () {
      expect(AuthRules.email(''), 'Enter your email');
      expect(AuthRules.email('nope'), 'Enter a valid email address');
      expect(AuthRules.email(' a@b.co '), isNull);
    });

    test('new password needs 6 characters', () {
      expect(AuthRules.newPassword('12345'), 'Password must be at least 6 characters');
      expect(AuthRules.newPassword('123456'), isNull);
    });
  });

  test('SignInWithEmail stops on bad input without calling the repository', () async {
    final r = await SignInWithEmail(repo)(email: 'bad', password: 'x');
    expect(r, isA<Err<Object?>>());
    expect((r as Err).failure, isA<ValidationFailure>());
    expect(repo.calls, isEmpty);
  });

  test('SignInWithEmail trims the email', () async {
    await SignInWithEmail(repo)(email: '  a@b.co ', password: 'secret');
    expect(repo.calls, ['signIn a@b.co']);
  });

  test('SignUpWithEmail checks name, email then password', () async {
    expect(message(await SignUpWithEmail(repo)(name: ' ', email: 'a@b.co', password: '123456')), 'Enter your name');
    expect(
      message(await SignUpWithEmail(repo)(name: 'Asha', email: 'a@b.co', password: '123')),
      'Password must be at least 6 characters',
    );
    expect(repo.calls, isEmpty);
    expect(await SignUpWithEmail(repo)(name: ' Asha ', email: 'a@b.co', password: '123456'), isA<Ok<void>>());
    expect(repo.calls, ['signUp Asha a@b.co']);
  });

  test('SendPasswordReset validates the email', () async {
    expect(message(await SendPasswordReset(repo)('')), 'Enter your email');
    await SendPasswordReset(repo)('a@b.co');
    expect(repo.calls, ['reset a@b.co']);
  });
}
