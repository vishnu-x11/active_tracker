import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

abstract final class Tables {
  static const profile = 'profile';
  static const gymSessions = 'gym_sessions';
  static const runs = 'runs';
  static const runPoints = 'run_points';
  static const water = 'water_entries';
  static const protein = 'protein_entries';
  static const presets = 'user_presets';
  static const goals = 'goals';

  static const routines = 'routines';

  static const settings = 'app_settings';

  static const all = [profile, gymSessions, runs, runPoints, water, protein, presets, goals, routines, settings];
}

class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const fileName = 'active_tracker_v2.db';

  static const version = 5;

  static Future<AppDatabase> open({String? path, DatabaseFactory? factory}) async {
    final f = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await f.getDatabasesPath(), fileName);
    final db = await f.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => _create(db),
        onUpgrade: (db, from, _) async {
          if (from >= 3) {
            if (from < 4) await db.execute(_settingsTable);
            if (from < 5) {
              await db.execute('ALTER TABLE ${Tables.gymSessions} ADD COLUMN exercises TEXT');
              await db.execute(_routinesTable);
            }
            return;
          }
          for (final t in Tables.all.reversed) {
            await db.execute('DROP TABLE IF EXISTS $t');
          }
          await _create(db);
        },
      ),
    );
    return AppDatabase._(db);
  }

  static const _sync = '''
    updated_at INTEGER NOT NULL,
    deleted INTEGER NOT NULL DEFAULT 0,
    synced INTEGER NOT NULL DEFAULT 0''';

  static const _settingsTable =
      'CREATE TABLE IF NOT EXISTS ${Tables.settings} (key TEXT PRIMARY KEY, value TEXT NOT NULL)';

  static const _routinesTable =
      '''
    CREATE TABLE IF NOT EXISTS ${Tables.routines} (
      sync_id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      exercises TEXT NOT NULL,
      $_sync
    )''';

  static Future<void> _create(Database db) async {
    final batch = db.batch()
      ..execute(_settingsTable)
      ..execute(_routinesTable)
      ..execute('''
        CREATE TABLE ${Tables.profile} (
          uid TEXT PRIMARY KEY,
          weight_kg REAL NOT NULL,
          height_cm REAL NOT NULL,
          age INTEGER,
          sex TEXT,
          burn_target_kcal INTEGER NOT NULL DEFAULT 600 CHECK (burn_target_kcal > 0),
          protein_g_per_kg REAL NOT NULL DEFAULT 1.6,
          water_ml_per_kg INTEGER NOT NULL DEFAULT 35,
          workout_water_boost INTEGER NOT NULL DEFAULT 1,
          theme_mode TEXT NOT NULL DEFAULT 'system',
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.gymSessions} (
          sync_id TEXT PRIMARY KEY,
          day TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          title TEXT NOT NULL,
          duration_min INTEGER NOT NULL CHECK (duration_min > 0),
          intensity TEXT NOT NULL,
          muscle_groups TEXT NOT NULL,
          weight_kg REAL NOT NULL,
          kcal INTEGER NOT NULL,
          exercises TEXT,
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.runs} (
          sync_id TEXT PRIMARY KEY,
          day TEXT NOT NULL,
          started_at INTEGER NOT NULL,
          title TEXT NOT NULL,
          run_type TEXT NOT NULL,
          source TEXT NOT NULL CHECK (source IN ('manual', 'gps')),
          draft INTEGER NOT NULL DEFAULT 0 CHECK (draft IN (0, 1)),
          distance_m INTEGER NOT NULL,
          moving_sec INTEGER NOT NULL,
          elevation_m INTEGER,
          effort INTEGER,
          weight_kg REAL NOT NULL,
          kcal INTEGER NOT NULL,
          kcal_override INTEGER,
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.runPoints} (
          run_sync_id TEXT NOT NULL REFERENCES ${Tables.runs}(sync_id) ON DELETE CASCADE,
          seq INTEGER NOT NULL,
          lat REAL NOT NULL,
          lng REAL NOT NULL,
          alt REAL,
          t INTEGER NOT NULL,
          segment INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY (run_sync_id, seq)
        )''')
      ..execute('''
        CREATE TABLE ${Tables.water} (
          sync_id TEXT PRIMARY KEY,
          day TEXT NOT NULL,
          at INTEGER NOT NULL,
          ml INTEGER NOT NULL CHECK (ml BETWEEN 1 AND 5000),
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.protein} (
          sync_id TEXT PRIMARY KEY,
          day TEXT NOT NULL,
          at INTEGER NOT NULL,
          grams REAL NOT NULL CHECK (grams > 0 AND grams <= 200),
          food TEXT,
          note TEXT,
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.presets} (
          sync_id TEXT PRIMARY KEY,
          kind TEXT NOT NULL CHECK (kind IN ('water', 'food', 'muscle_group', 'run_type')),
          label TEXT NOT NULL,
          value REAL,
          unit TEXT,
          sort INTEGER NOT NULL DEFAULT 0,
          $_sync
        )''')
      ..execute('''
        CREATE TABLE ${Tables.goals} (
          sync_id TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          period TEXT NOT NULL CHECK (period IN ('week', 'month')),
          target REAL NOT NULL,
          created_at INTEGER NOT NULL,
          $_sync
        )''');
    for (final t in [Tables.gymSessions, Tables.runs, Tables.water, Tables.protein]) {
      batch.execute('CREATE INDEX idx_${t}_day ON $t(day, deleted)');
    }
    for (final t in [
      Tables.gymSessions,
      Tables.runs,
      Tables.water,
      Tables.protein,
      Tables.presets,
      Tables.goals,
      Tables.routines,
    ]) {
      batch.execute('CREATE INDEX idx_${t}_unsynced ON $t(synced) WHERE synced = 0');
    }
    await batch.commit(noResult: true);
  }

  Future<String?> setting(String key) async {
    final rows = await db.query(Tables.settings, where: 'key = ?', whereArgs: [key]);
    return rows.isEmpty ? null : rows.single['value']! as String;
  }

  Future<void> setSetting(String key, String value) =>
      db.insert(Tables.settings, {'key': key, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> close() => db.close();
}
