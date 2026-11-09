import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/auth/domain/entities/auth_rules.dart';
import 'package:active_tracker/features/auth/domain/use_cases/send_password_reset.dart';
import 'package:active_tracker/features/auth/domain/use_cases/send_phone_code.dart';
import 'package:active_tracker/features/auth/domain/use_cases/sign_in_with_email.dart';
import 'package:active_tracker/features/auth/domain/use_cases/sign_up_with_email.dart';
import 'package:active_tracker/features/auth/domain/use_cases/verify_phone_code.dart';
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

    test('phone number and E.164', () {
      expect(AuthRules.phoneNumber(''), 'Enter your phone number');
      expect(AuthRules.phoneNumber('12ab'), 'Enter a valid phone number');
      expect(AuthRules.phoneNumber('98765 43210'), isNull);
      expect(AuthRules.countryCode('91'), 'Use a code like +91');
      expect(AuthRules.e164('+91', '098765-43210'), '+919876543210');
    });

    test('sms code is exactly 6 digits', () {
      expect(AuthRules.smsCode('12345'), 'Enter the 6-digit code');
      expect(AuthRules.smsCode('123456'), isNull);
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

  test('SendPhoneCode sends E.164 to the repository', () async {
    expect(message(await SendPhoneCode(repo)(countryCode: '+91', number: '12')), 'Enter a valid phone number');
    await SendPhoneCode(repo)(countryCode: '+91', number: '98765 43210');
    expect(repo.calls, ['sendCode +919876543210 -']);
  });

  test('VerifyPhoneCode rejects short codes', () async {
    expect(message(await VerifyPhoneCode(repo)(verificationId: 'v', smsCode: '12')), 'Enter the 6-digit code');
    await VerifyPhoneCode(repo)(verificationId: 'v', smsCode: '123456');
    expect(repo.calls, ['verify v 123456']);
  });
}
