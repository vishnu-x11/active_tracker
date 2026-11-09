import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/dates.dart';
import '../../../../core/result.dart';
import '../../../progress/progress.dart';
import '../../domain/entities/protein.dart';
import '../providers.dart';
import '../states/protein_entry_state.dart';

final proteinProvider = NotifierProvider.autoDispose<ProteinNotifier, ProteinEntryState>(ProteinNotifier.new);

class ProteinNotifier extends Notifier<ProteinEntryState> {
  @override
  ProteinEntryState build() => const ProteinEntryState();

  void open({bool asNewFood = false}) => state = ProteinEntryState(adding: true, saveFood: asNewFood);
  void close() => state = state.copyWith(adding: false);
  void setFood(String v) => state = state.copyWith(food: v, error: () => null);
  void setGrams(String v) => state = state.copyWith(gramsText: v, error: () => null);
  void setMinute(int m) => state = state.copyWith(minute: () => m);
  void toggleSaveFood() => state = state.copyWith(saveFood: !state.saveFood);

  void _refresh(String day) {
    invalidateDay(ref, day);
    ref.invalidate(proteinDayProvider(day));
  }

  Future<ProteinEntry?> quickAdd(double grams, {String? food}) async {
    final result = await ref.read(logProteinProvider)(gramsText: '$grams', food: food ?? '');
    if (!ref.mounted) return null;
    if (result case Ok(:final value)) {
      _refresh(value.day);
      return value;
    }
    return null;
  }

  Future<ProteinEntry?> addCustom() async {
    if (state.saving) return null;
    state = state.copyWith(showErrors: true, saving: true, error: () => null);
    final now = DateTime.now();
    final m = state.minute;
    final result = await ref.read(logProteinProvider)(
      gramsText: state.gramsText,
      food: state.food,
      saveFood: state.saveFood,
      at: m == null ? null : dateOnly(now).add(Duration(minutes: m)),
    );
    if (!ref.mounted) return null;
    switch (result) {
      case Ok(:final value):
        _refresh(value.day);
        if (state.saveFood) ref.invalidate(foodsProvider);
        state = const ProteinEntryState();
        return value;
      case Err(failure: ValidationFailure(:final message)):
        state = state.copyWith(saving: false, error: () => message);
      case Err(:final failure):
        state = state.copyWith(saving: false, error: () => failure.message);
    }
    return null;
  }

  Future<void> remove(ProteinEntry e) async {
    if (!ref.mounted) return;
    await ref.read(deleteProteinProvider)(e.id);
    if (ref.mounted) _refresh(e.day);
  }
}
