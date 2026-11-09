import '../../domain/entities/auth_rules.dart';

enum LoginBusy { none, email, google }

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.showErrors = false,
    this.busy = LoginBusy.none,
    this.error,
  });

  final String email;
  final String password;

  final bool showErrors;
  final LoginBusy busy;

  final String? error;

  String? get emailError => showErrors ? AuthRules.email(email) : null;
  String? get passwordError => showErrors ? AuthRules.password(password) : null;
  bool get isBusy => busy != LoginBusy.none;

  LoginState copyWith({
    String? email,
    String? password,
    bool? showErrors,
    LoginBusy? busy,
    String? Function()? error,
  }) => LoginState(
    email: email ?? this.email,
    password: password ?? this.password,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is LoginState &&
      other.email == email &&
      other.password == password &&
      other.showErrors == showErrors &&
      other.busy == busy &&
      other.error == error;

  @override
  int get hashCode => Object.hash(email, password, showErrors, busy, error);
}
