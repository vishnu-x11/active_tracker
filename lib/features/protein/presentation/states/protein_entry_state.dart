import '../../domain/use_cases/protein_use_cases.dart';

class ProteinEntryState {
  const ProteinEntryState({
    this.adding = false,
    this.food = '',
    this.gramsText = '',
    this.minute,
    this.saveFood = false,
    this.showErrors = false,
    this.saving = false,
    this.error,
  });

  final bool adding;
  final String food;
  final String gramsText;

  final int? minute;
  final bool saveFood;
  final bool showErrors;
  final bool saving;
  final String? error;

  String? get problem => showErrors ? LogProtein.problem(gramsText: gramsText, food: food, saveFood: saveFood) : null;

  ProteinEntryState copyWith({
    bool? adding,
    String? food,
    String? gramsText,
    int? Function()? minute,
    bool? saveFood,
    bool? showErrors,
    bool? saving,
    String? Function()? error,
  }) => ProteinEntryState(
    adding: adding ?? this.adding,
    food: food ?? this.food,
    gramsText: gramsText ?? this.gramsText,
    minute: minute != null ? minute() : this.minute,
    saveFood: saveFood ?? this.saveFood,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is ProteinEntryState &&
      other.adding == adding &&
      other.food == food &&
      other.gramsText == gramsText &&
      other.minute == minute &&
      other.saveFood == saveFood &&
      other.showErrors == showErrors &&
      other.saving == saving &&
      other.error == error;

  @override
  int get hashCode => Object.hash(adding, food, gramsText, minute, saveFood, showErrors, saving, error);
}
