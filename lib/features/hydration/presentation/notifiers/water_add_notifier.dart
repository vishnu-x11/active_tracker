import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/result.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/water_entry.dart';
import '../../domain/use_cases/water_use_cases.dart';
import '../providers.dart';
import '../states/water_add_state.dart';

final waterAddProvider = NotifierProvider.autoDispose<WaterAddNotifier, WaterAddState>(WaterAddNotifier.new);

class WaterAddNotifier extends Notifier<WaterAddState> {
  @override
  WaterAddState build() => const WaterAddState();

  String _format(int ml) => state.unit == WaterUnit.ml
      ? '$ml'
      : (ml / 1000).toStringAsFixed(2).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');

  void pick(Drink d) =>
      state = state.copyWith(drink: d, amountText: d.ml == null ? state.amountText : _format(d.ml!), error: () => null);

  void setAmount(String v) {
    final ml = LogWater.toMl(v, state.unit);
    final match = Drink.values.where((d) => d.ml != null && d.ml == ml).firstOrNull;
    state = state.copyWith(amountText: v, drink: match ?? Drink.custom, error: () => null);
  }

  void nudge(int dir) {
    final ml = ((state.ml ?? 0) + 50 * dir).clamp(50, 5000);
    setAmount(_format(ml));
  }

  void setUnit(WaterUnit u) {
    if (u == state.unit) return;
    final ml = state.ml;
    state = state.copyWith(unit: u);
    if (ml != null) state = state.copyWith(amountText: _format(ml));
  }

  Future<WaterEntry?> add() async {
    if (state.saving) return null;
    state = state.copyWith(showErrors: true, saving: true, error: () => null);
    final result = await ref.read(logWaterProvider)(state.amountText, state.unit);
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        invalidateDay(ref, value.day);
        ref.invalidate(waterDayProvider(value.day));
        state = state.copyWith(saving: false, showErrors: false);
        return value;
      case Err(failure: ValidationFailure()):
        state = state.copyWith(saving: false);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
    }
    return null;
  }

  Future<void> undo(WaterEntry entry) async {
    if (!ref.mounted) return;
    await ref.read(deleteWaterProvider)(entry.id);
    if (!ref.mounted) return;
    invalidateDay(ref, entry.day);
    ref.invalidate(waterDayProvider(entry.day));
  }
}
