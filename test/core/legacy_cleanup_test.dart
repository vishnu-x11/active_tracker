import 'dart:io';

import 'package:active_tracker/core/storage/legacy_cleanup.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  test('deletes the old database and Hive files, keeps everything else', () async {
    final tmp = await Directory.systemTemp.createTemp('legacy');
    addTearDown(() => tmp.delete(recursive: true));
    final factory = databaseFactoryFfi;
    await factory.setDatabasesPath(tmp.path);
    final old = await factory.openDatabase(p.join(tmp.path, LegacyCleanup.oldDatabase));
    await old.close();
    final docs = await Directory(p.join(tmp.path, 'docs')).create();
    for (final name in ['user_profile.hive', 'user_profile.lock', 'keep.txt']) {
      await File(p.join(docs.path, name)).writeAsString('x');
    }

    await LegacyCleanup.run(factory: factory, documents: () async => docs);

    expect(await factory.databaseExists(p.join(tmp.path, LegacyCleanup.oldDatabase)), isFalse);
    expect(docs.listSync().map((e) => p.basename(e.path)), ['keep.txt']);
  });
}
