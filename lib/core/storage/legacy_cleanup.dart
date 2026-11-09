import 'dart:developer' as developer;
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

abstract final class LegacyCleanup {
  static const oldDatabase = 'active_tracker.db';

  static Future<void> run({DatabaseFactory? factory, Future<Directory> Function()? documents}) async {
    try {
      final f = factory ?? databaseFactory;
      final dbPath = p.join(await f.getDatabasesPath(), oldDatabase);
      if (await f.databaseExists(dbPath)) await f.deleteDatabase(dbPath);

      final dir = await (documents ?? getApplicationDocumentsDirectory)();
      await for (final e in dir.list()) {
        if (e is File && (e.path.endsWith('.hive') || e.path.endsWith('.lock'))) await e.delete();
      }
    } catch (e, st) {
      developer.log('Legacy cleanup failed', error: e, stackTrace: st, name: 'startup');
    }
  }
}
