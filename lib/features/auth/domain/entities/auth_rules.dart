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
}
