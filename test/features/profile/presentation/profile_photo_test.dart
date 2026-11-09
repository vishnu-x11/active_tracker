import 'dart:typed_data';

import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/core/storage/app_database.dart';
import 'package:active_tracker/features/profile/data/data_sources/profile_local_data_source.dart';
import 'package:active_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/profile/domain/use_cases/profile_photo.dart';
import 'package:active_tracker/features/profile/presentation/providers.dart';
import 'package:active_tracker/features/profile/profile_routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../helpers/app_harness.dart';
import '../../../helpers/pump.dart';

final pixel = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

class FakePicker implements PhotoPicker {
  FakePicker(this.result);

  Result<Uint8List?> result;
  final asked = <PhotoSource>[];

  @override
  Future<Result<Uint8List?>> pick(PhotoSource source) async {
    asked.add(source);
    return result;
  }
}

void main() {
  sqfliteFfiInit();

  test('a photo is saved with the profile; too large is refused; removing clears it', () async {
    final db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    final repo = ProfileRepositoryImpl(ProfileLocalDataSourceImpl(db));
    const profile = Profile(weightKg: 75, heightCm: 178, burnTargetKcal: 600);
    final set = SetProfilePhoto(repo);

    final withPhoto = (await set('p1', profile, pixel)).valueOrNull!;
    expect((await repo.get('p1')).valueOrNull!.photo, withPhoto.photo);
    expect(withPhoto.photo, isNotNull);

    final big = await set('p1', withPhoto, Uint8List(SetProfilePhoto.maxBytes + 1));
    expect((big as Err).failure.message, 'That photo is too large. Please pick another one.');

    await set('p1', withPhoto, null);
    expect((await repo.get('p1')).valueOrNull!.photo, isNull);
  });

  testWidgets('tap the avatar to choose, show and remove a photo', (tester) async {
    final picker = FakePicker(Ok(pixel));
    final db = await pumpFeature(
      tester,
      routes: [
        ShellRoute(
          builder: (c, s, child) => Scaffold(body: child),
          routes: [ProfileRoutes.tab()],
        ),
      ],
      initial: ProfileRoutes.profile,
      overrides: [photoPickerProvider.overrideWithValue(picker)],
    );
    final avatar = find.bySemanticsLabel('Profile photo. Change photo');
    expect(find.text('TU'), findsOneWidget);

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.text('Remove photo'), findsNothing);
    await tester.tap(find.text('Choose from gallery'));
    await settleWithIo(tester);
    expect(picker.asked, [PhotoSource.gallery]);
    expect(find.text('TU'), findsNothing);
    final row = await tester.runAsync(() => db.db.query(Tables.profile));
    expect(row!.single['photo'], isNotNull);
    expect(row.single['synced'], 0);

    picker.result = const Err(DeviceFailure("Couldn't open the camera. Allow camera access in Settings."));
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Take photo'));
    await settleWithIo(tester);
    expect(find.text("Couldn't open the camera. Allow camera access in Settings."), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    await tester.tap(avatar);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Remove photo'));
    await settleWithIo(tester);
    expect(find.text('TU'), findsOneWidget);
  });
}
