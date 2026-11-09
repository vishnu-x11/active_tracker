import '../../domain/entities/water_entry.dart';
import '../../domain/use_cases/water_use_cases.dart';

class WaterAddState {
  const WaterAddState({
    this.drink = Drink.glass,
    this.amountText = '250',
    this.unit = WaterUnit.ml,
    this.showErrors = false,
    this.saving = false,
    this.error,
  });

  final Drink drink;
  final String amountText;
  final WaterUnit unit;
  final bool showErrors;
  final bool saving;
  final String? error;

  int? get ml => LogWater.toMl(amountText, unit);
  String? get problem => showErrors ? LogWater.problem(amountText, unit) : null;

  WaterAddState copyWith({
    Drink? drink,
    String? amountText,
    WaterUnit? unit,
    bool? showErrors,
    bool? saving,
    String? Function()? error,
  }) => WaterAddState(
    drink: drink ?? this.drink,
    amountText: amountText ?? this.amountText,
    unit: unit ?? this.unit,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
  );

  @override
  bool operator ==(Object other) =>
      other is WaterAddState &&
      other.drink == drink &&
      other.amountText == amountText &&
      other.unit == unit &&
      other.showErrors == showErrors &&
      other.saving == saving &&
      other.error == error;

  @override
  int get hashCode => Object.hash(drink, amountText, unit, showErrors, saving, error);
}
