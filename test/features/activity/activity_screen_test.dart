import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/activity/presentation/screens/activity_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/pump.dart';
import '../../helpers/seed.dart';

void main() {
  sqfliteFfiInit();

  testWidgets('date strip, filter and grouped list', (tester) async {
    tester.view
      ..physicalSize = const Size(1170, 2532)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      final s = Seed(db);
      await s.gym(DateTime(2026, 11, 5, 18, 30), kcal: 712);
      await s.run(DateTime(2026, 11, 5, 6, 45), kcal: 405);
      await s.gym(DateTime(2026, 11, 2, 19), kcal: 655, title: 'Legs', minutes: 115);
      return db;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          todayProvider.overrideWithValue(DateTime(2026, 11, 5)),
          selectedDayProvider.overrideWith(() => _FixedDay(DateTime(2026, 11, 5))),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: const [AppPalette.dark]),
          home: const Scaffold(body: ActivityScreen()),
        ),
      ),
    );
    await settleWithIo(tester, rounds: 10);

    expect(find.text('November 2026'), findsOneWidget);
    expect(find.text('Showing all days · pick a day'), findsOneWidget);
    expect(find.text('Today · Thu, 5 Nov'), findsOneWidget);
    expect(find.text('Mon, 2 Nov'), findsOneWidget);
    expect(find.bySemanticsLabel('Mon 2 November, workout logged'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('Mon 2 November, workout logged'));
    await settleWithIo(tester);
    expect(find.text('Showing Mon, 2 Nov · tap again for all'), findsOneWidget);
    expect(find.text('Legs'), findsOneWidget);
    expect(find.text('Today · Thu, 5 Nov'), findsNothing);

    await tester.tap(find.bySemanticsLabel('Mon 2 November, workout logged'));
    await settleWithIo(tester);
    await tester.tap(find.text('Runs'));
    await settleWithIo(tester);
    expect(find.text('Morning Run'), findsOneWidget);
    expect(find.text('Legs'), findsNothing);
    expect(find.text('6:45 AM · GPS'), findsOneWidget);
  });
}

class _FixedDay extends SelectedDayNotifier {
  _FixedDay(this.day);
  final DateTime day;

  @override
  DateTime build() => day;
}
