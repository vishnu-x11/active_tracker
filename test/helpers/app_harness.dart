import 'package:active_tracker/core/providers/core_providers.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/core/theme/app_palette.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/running/data/data_sources/speaker.dart';
import 'package:active_tracker/features/running/presentation/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fake_speaker.dart';
import 'pump.dart';

Future<AppDatabase> pumpFeature(
  WidgetTester tester, {
  required List<RouteBase> routes,
  required String initial,
  String uid = 'u',
  AppPalette palette = AppPalette.dark,
  double height = 4200,
  double width = 390,
  List<Override> overrides = const [],
  Future<void> Function(AppDatabase db)? seed,
  GlobalKey<NavigatorState>? navigatorKey,
  Speaker? speaker,
}) async {
  sqfliteFfiInit();
  tester.view
    ..physicalSize = Size(width * 3, height)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final db = await tester.runAsync(() async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    for (final t in Tables.all.reversed) {
      await db.db.delete(t);
    }
    await ProfileLocalDataSourceImpl(db).upsert(uid, const Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600));
    await seed?.call(db);
    return db;
  });
  var n = 0;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(db!),
        currentUidProvider.overrideWith((ref) => Stream.value(uid)),
        newIdProvider.overrideWithValue(() => 'id${n++}'),
        displayNameProvider.overrideWithValue('Test User'),
        accountLabelProvider.overrideWithValue('test@example.com'),
        photoUrlProvider.overrideWithValue(null),
        speakerProvider.overrideWithValue(speaker ?? FakeSpeaker()),
        ...overrides,
      ],
      child: MaterialApp.router(
        theme: ThemeData(extensions: [palette]),
        routerConfig: GoRouter(navigatorKey: navigatorKey, initialLocation: initial, routes: routes),
      ),
    ),
  );
  await settleWithIo(tester);
  return db;
}
