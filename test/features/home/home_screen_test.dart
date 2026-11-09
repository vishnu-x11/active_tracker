import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/home/presentation/screens/home_screen.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../helpers/pump.dart';
import '../../helpers/seed.dart';

void main() {
  sqfliteFfiInit();
  final thu = DateTime(2026, 11, 5);

  Future<void> pumpHome(
    WidgetTester tester, {
    required String uid,
    Future<void> Function(Seed)? seed,
    AppPalette palette = AppPalette.dark,
  }) async {
    tester.view
      ..physicalSize = const Size(1170, 4200)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final db = await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      for (final t in [Tables.gymSessions, Tables.runs, Tables.water, Tables.protein]) {
        await db.db.delete(t);
      }
      await ProfileLocalDataSourceImpl(db).upsert(uid, const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
      await seed?.call(Seed(db));
      return db;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          currentUidProvider.overrideWith((ref) => Stream.value(uid)),
          displayNameProvider.overrideWithValue('Vishnu P V'),
          todayProvider.overrideWithValue(thu),
        ],
        child: MaterialApp(
          theme: ThemeData(extensions: [palette]),
          home: const Scaffold(body: HomeScreen()),
        ),
      ),
    );
    await settleWithIo(tester, rounds: 10);
  }

  testWidgets('the design example day', (tester) async {
    await pumpHome(
      tester,
      uid: 'home-1',
      seed: (s) async {
        await s.gym(thu.add(const Duration(hours: 18, minutes: 30)), kcal: 712);
        await s.run(thu.add(const Duration(hours: 6, minutes: 45)), kcal: 405);
        await s.water(thu.add(const Duration(hours: 9)), 1750);
        await s.protein(thu.add(const Duration(hours: 13)), 86);
        await s.gym(DateTime(2026, 11, 2, 19), kcal: 655, title: 'Legs');
        await s.gym(DateTime(2026, 11, 4, 18), kcal: 588, title: 'Back');
        await s.run(DateTime(2026, 11, 4, 6), kcal: 405);
        await s.gym(DateTime(2026, 10, 28, 18), kcal: 2468, title: 'Last week');
      },
    );

    expect(find.text('Vishnu'), findsOneWidget);
    expect(find.text('1,117 kcal'), findsOneWidget);
    expect(find.text('517 over target'), findsOneWidget);
    expect(find.bySemanticsLabel('Water 1.75 of 3.1 L, 56% of target'), findsOneWidget);
    expect(find.bySemanticsLabel('Protein 86 of 120 g, 72% of target'), findsOneWidget);
    expect(find.text('Target hit · +86%'), findsOneWidget);
    expect(find.text('Shoulders + Triceps'), findsOneWidget);
    expect(find.text('6:45 AM · 5.20 km · 5:41 /km'), findsOneWidget);
    expect(find.text('2,765 kcal'), findsOneWidget);
    expect(find.text('+12% vs last week'), findsOneWidget);
  });

  testWidgets('an empty day (light theme)', (tester) async {
    await pumpHome(tester, uid: 'home-2', palette: AppPalette.light);
    expect(find.text('0 kcal'), findsNWidgets(2));
    expect(find.text('600 kcal to go'), findsOneWidget);
    expect(find.text('No workouts yet today'), findsOneWidget);
    expect(find.bySemanticsLabel('Water 0.00 of 2.6 L, 0% of target'), findsOneWidget);
  });
}
