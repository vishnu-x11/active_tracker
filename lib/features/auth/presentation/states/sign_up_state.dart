import '../../domain/entities/auth_rules.dart';

class SignUpState {
  const SignUpState({
    this.name = '',
    this.email = '',
    this.password = '',
    this.showErrors = false,
    this.busy = false,
    this.error,
    this.done = false,
  });

  final String name;
  final String email;
  final String password;
  final bool showErrors;
  final bool busy;
  final String? error;

  final bool done;

  String? get nameError => showErrors ? AuthRules.name(name) : null;
  String? get emailError => showErrors ? AuthRules.email(email) : null;
  String? get passwordError => showErrors ? AuthRules.newPassword(password) : null;

  SignUpState copyWith({
    String? name,
    String? email,
    String? password,
    bool? showErrors,
    bool? busy,
    String? Function()? error,
    bool? done,
  }) => SignUpState(
    name: name ?? this.name,
    email: email ?? this.email,
    password: password ?? this.password,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
    done: done ?? this.done,
  );

  @override
  bool operator ==(Object other) =>
      other is SignUpState &&
      other.name == name &&
      other.email == email &&
      other.password == password &&
      other.showErrors == showErrors &&
      other.busy == busy &&
      other.error == error &&
      other.done == done;

  @override
  int get hashCode => Object.hash(name, email, password, showErrors, busy, error, done);
}
