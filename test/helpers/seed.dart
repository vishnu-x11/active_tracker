import 'package:active_tracker/core/storage/app_database.dart';

class Seed {
  Seed(this.db);

  final AppDatabase db;
  var _n = 0;

  Map<String, Object?> _sync() => {'updated_at': 1000 + _n, 'deleted': 0, 'synced': 0};

  Future<void> gym(
    DateTime at, {
    required int kcal,
    String title = 'Shoulders + Triceps',
    int minutes = 120,
    String intensity = 'moderate',
    bool deleted = false,
  }) => db.db.insert(Tables.gymSessions, {
    'sync_id': 'g${_n++}',
    'day': _day(at),
    'started_at': at.millisecondsSinceEpoch,
    'title': title,
    'duration_min': minutes,
    'intensity': intensity,
    'muscle_groups': '[]',
    'weight_kg': 75,
    'kcal': kcal,
    ..._sync(),
    'deleted': deleted ? 1 : 0,
  });

  Future<void> run(
    DateTime at, {
    required int kcal,
    int? override,
    double km = 5.2,
    int seconds = 1775,
    String title = 'Morning Run',
    bool gps = true,
    bool draft = false,
  }) => db.db.insert(Tables.runs, {
    'sync_id': 'r${_n++}',
    'day': _day(at),
    'started_at': at.millisecondsSinceEpoch,
    'title': title,
    'run_type': 'outdoor',
    'source': gps ? 'gps' : 'manual',
    'draft': draft ? 1 : 0,
    'distance_m': (km * 1000).round(),
    'moving_sec': seconds,
    'weight_kg': 75,
    'kcal': kcal,
    'kcal_override': override,
    ..._sync(),
  });

  Future<void> water(DateTime at, int ml) => db.db.insert(Tables.water, {
    'sync_id': 'w${_n++}',
    'day': _day(at),
    'at': at.millisecondsSinceEpoch,
    'ml': ml,
    ..._sync(),
  });

  Future<void> protein(DateTime at, double grams) => db.db.insert(Tables.protein, {
    'sync_id': 'p${_n++}',
    'day': _day(at),
    'at': at.millisecondsSinceEpoch,
    'grams': grams,
    ..._sync(),
  });

  static String _day(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
