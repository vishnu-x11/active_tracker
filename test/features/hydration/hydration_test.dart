import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/hydration/data/data_sources/water_local_data_source.dart';
import 'package:active_tracker/features/hydration/data/repositories/water_repository_impl.dart';
import 'package:active_tracker/features/hydration/domain/entities/water_entry.dart';
import 'package:active_tracker/features/hydration/domain/use_cases/water_use_cases.dart';
import 'package:active_tracker/features/hydration/hydration_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/app_harness.dart';
import '../../helpers/pump.dart';

void main() {
  sqfliteFfiInit();

  test('amount rules: 1 ml to 5 L, in ml or L', () {
    expect(LogWater.toMl('0.33', WaterUnit.l), 330);
    expect(LogWater.problem('', WaterUnit.ml), 'Enter an amount');
    expect(LogWater.problem('0', WaterUnit.ml), 'Enter at least 1 ml');
    expect(LogWater.problem('5.1', WaterUnit.l), 'One entry can be at most 5 L');
    expect(LogWater.problem('5', WaterUnit.l), isNull);
  });

  test('a drink is stamped now and can be removed', () async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    await db.db.delete(Tables.water);
    final repo = WaterRepositoryImpl(WaterLocalDataSourceImpl(db));
    final at = DateTime(2026, 11, 5, 15, 20);
    final e = (await LogWater(repo, newId: () => 'w1', now: () => at)('330', WaterUnit.ml)).valueOrNull!;
    expect((e.day, e.at, e.ml), ('2026-11-05', at, 330));
    expect((await repo.entriesFor('2026-11-05')).valueOrNull, [e]);
    await DeleteWater(repo)('w1');
    expect((await repo.entriesFor('2026-11-05')).valueOrNull, isEmpty);
    expect((await LogWater(repo, newId: () => 'x')('abc', WaterUnit.ml)) is Err, isTrue);
  });

  testWidgets('bottle with a minimal logger: type, step, add, undo; the undo message goes away', (tester) async {
    await pumpFeature(tester, routes: HydrationRoutes.routes, initial: HydrationRoutes.water, height: 2532);
    expect(find.text('Bottle'), findsNothing);
    expect(find.text('L'), findsNothing);

    await tester.enterText(find.byType(TextField), '330');
    await tester.tap(find.text('Add'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('330 ml'), findsOneWidget);

    await tester.tap(find.byTooltip('50 ml more'));
    await tester.pump();
    expect(find.text('380'), findsOneWidget);
    await tester.tap(find.text('Add'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('710 ml'), findsOneWidget);

    await tester.tap(find.text('Undo'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('330 ml'), findsOneWidget);

    await tester.tap(find.text('Add'));
    await settleWithIo(tester, rounds: 8);
    expect(find.text('Undo'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);

    await tester.enterText(find.byType(TextField), '6000');
    await tester.tap(find.text('Add'));
    await settleWithIo(tester);
    expect(find.text('One entry can be at most 5 L'), findsOneWidget);
  });

  testWidgets('history shows 7 day cards without drink times', (tester) async {
    await pumpFeature(tester, routes: HydrationRoutes.routes, initial: HydrationRoutes.history, height: 6000);
    expect(find.textContaining('Last 7 days'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Water \d+%$')), findsNWidgets(7));
    expect(find.textContaining('Last drink'), findsNothing);
  });
}
