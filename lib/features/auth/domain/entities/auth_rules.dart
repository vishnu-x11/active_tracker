abstract final class AuthRules {
  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static const minPasswordLength = 6;

  static String? email(String value) {
    final v = value.trim();
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? password(String value) => value.isEmpty ? 'Enter your password' : null;

  static String? newPassword(String value) {
    if (value.isEmpty) return 'Choose a password';
    if (value.length < minPasswordLength) return 'Password must be at least $minPasswordLength characters';
    return null;
  }

  static String? name(String value) => value.trim().isEmpty ? 'Enter your name' : null;

  static String? countryCode(String value) =>
      RegExp(r'^\+\d{1,4}$').hasMatch(value.trim()) ? null : 'Use a code like +91';

  static String? phoneNumber(String value) {
    final digits = value.replaceAll(RegExp(r'[\s-]'), '');
    if (digits.isEmpty) return 'Enter your phone number';
    if (!RegExp(r'^\d{6,14}$').hasMatch(digits)) return 'Enter a valid phone number';
    return null;
  }

  static String e164(String countryCode, String number) =>
      '${countryCode.trim()}${number.replaceAll(RegExp(r'[\s-]'), '').replaceFirst(RegExp(r'^0+'), '')}';

  static const codeLength = 6;

  static String? smsCode(String value) =>
      RegExp('^\\d{$codeLength}\$').hasMatch(value) ? null : 'Enter the $codeLength-digit code';
}
