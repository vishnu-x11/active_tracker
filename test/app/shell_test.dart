import 'package:active_tracker/app/router.dart';
import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/pump.dart';

void main() {
  sqfliteFfiInit();

  Future<void> pumpApp(WidgetTester tester, AppPalette palette) async {
    final db = await tester.runAsync(() async {
      final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
      await ProfileLocalDataSourceImpl(
        db,
      ).upsert('test-uid', const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
      return db;
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db!),
          displayNameProvider.overrideWithValue('Test User'),
          accountLabelProvider.overrideWithValue('test@example.com'),
          photoUrlProvider.overrideWithValue(null),
          todayProvider.overrideWithValue(DateTime(2026, 11, 5)),
          currentUidProvider.overrideWith((ref) => Stream.value('test-uid')),
        ],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp.router(
            theme: ThemeData(extensions: [palette]),
            routerConfig: ref.watch(routerProvider),
          ),
        ),
      ),
    );
    await settleWithIo(tester);
  }

  for (final (name, palette) in [('light', AppPalette.light), ('dark', AppPalette.dark)]) {
    testWidgets('tab bar switches tabs ($name)', (tester) async {
      await pumpApp(tester, palette);
      expect(find.text('BURNED TODAY'), findsOneWidget);
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Activity'), findsOneWidget);
      expect(find.text('Progress'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      await tester.tap(find.text('Progress'));
      await settleWithIo(tester);
      expect(find.text('ACTIVE STREAK'), findsOneWidget);
    });
  }

  testWidgets('+ opens the log screen', (tester) async {
    await pumpApp(tester, AppPalette.dark);
    await tester.tap(find.byTooltip('Log activity'));
    await tester.pumpAndSettle();
    expect(find.text('Log for Today'), findsOneWidget);
    expect(find.text('Gym session'), findsOneWidget);
  });
}
