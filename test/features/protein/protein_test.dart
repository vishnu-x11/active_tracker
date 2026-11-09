import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/protein/domain/entities/protein.dart';
import 'package:active_tracker/features/protein/domain/repositories/protein_repository.dart';
import 'package:active_tracker/features/protein/domain/use_cases/protein_use_cases.dart';
import 'package:active_tracker/features/protein/protein_routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';

class _Repo implements ProteinRepository {
  final entries = <ProteinEntry>[];
  final saved = <Food>[];

  @override
  Future<Result<void>> add(ProteinEntry entry) async {
    entries.add(entry);
    return const Ok(null);
  }

  @override
  Future<Result<void>> delete(String id) async => const Ok(null);

  @override
  Future<Result<List<ProteinEntry>>> entriesFor(String day) async => Ok(entries);

  @override
  Future<Result<List<Food>>> foods() async => Ok(saved);

  @override
  Future<Result<void>> saveFood(Food food) async {
    saved.add(food);
    return const Ok(null);
  }
}

void main() {
  test('rules', () {
    String? p(String g, {String food = '', bool save = false}) =>
        LogProtein.problem(gramsText: g, food: food, saveFood: save);
    expect(p(''), 'Enter the grams of protein');
    expect(p('0'), 'Enter at least 0.1 g');
    expect(p('201'), 'One entry can be at most 200 g');
    expect(p('26', save: true), 'Name the food to save it');
    expect(p('26', food: 'Soya', save: true), isNull);
  });

  test('saving a food puts it first and hides the starter with the same name', () async {
    final repo = _Repo();
    var n = 0;
    final log = LogProtein(repo, newId: () => 'i${n++}', now: () => DateTime(2026, 11, 5, 17, 30));
    await log(gramsText: '22.25', food: 'Eggs', saveFood: true);
    expect(repo.entries.single.grams, 22.3);
    final foods = (await GetFoods(repo)()).valueOrNull!;
    expect(foods.first.name, 'Eggs');
    expect(foods.where((f) => f.name == 'Eggs'), hasLength(1));
    expect(foods, hasLength(4));
  });

  testWidgets('quick add, a food, then remove', (tester) async {
    await pumpFeature(tester, routes: [ProteinRoutes.route], initial: ProteinRoutes.protein);
    expect(find.text('Nothing logged yet. Use quick add or your foods.'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Add 20 grams'));
    await settleWithIo(tester, rounds: 8);
    await tester.tap(find.byTooltip('Add Eggs'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('38 g'), findsOneWidget);
    expect(find.text('Eggs 3 whole'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove Eggs 3 whole'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('20 g'), findsNWidgets(3));
    expect(find.text('Eggs 3 whole'), findsNothing);
  });
}
