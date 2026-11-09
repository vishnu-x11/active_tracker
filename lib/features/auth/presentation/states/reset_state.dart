import '../../domain/entities/auth_rules.dart';

class ResetState {
  const ResetState({this.email = '', this.showErrors = false, this.busy = false, this.error, this.sentTo});

  final String email;
  final bool showErrors;
  final bool busy;
  final String? error;

  final String? sentTo;

  String? get emailError => showErrors ? AuthRules.email(email) : null;

  ResetState copyWith({
    String? email,
    bool? showErrors,
    bool? busy,
    String? Function()? error,
    String? Function()? sentTo,
  }) => ResetState(
    email: email ?? this.email,
    showErrors: showErrors ?? this.showErrors,
    busy: busy ?? this.busy,
    error: error != null ? error() : this.error,
    sentTo: sentTo != null ? sentTo() : this.sentTo,
  );

  @override
  bool operator ==(Object other) =>
      other is ResetState &&
      other.email == email &&
      other.showErrors == showErrors &&
      other.busy == busy &&
      other.error == error &&
      other.sentTo == sentTo;

  @override
  int get hashCode => Object.hash(email, showErrors, busy, error, sentTo);
}
