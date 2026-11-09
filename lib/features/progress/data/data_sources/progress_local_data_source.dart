import '../../../../core/storage/app_database.dart';
import '../../domain/entities/activity_item.dart';
import '../../domain/entities/day_totals.dart';
import '../../domain/entities/goal.dart';
import '../models/activity_row_mapper.dart';

abstract interface class ProgressLocalDataSource {
  Future<DayTotals> dayTotals(String day);
  Future<Map<String, int>> burnByDay(String from, String to);
  Future<Set<String>> activeDays(String from, String to);
  Future<List<ActivityItem>> activities(String from, String to);
  Future<Map<String, DayTotals>> daySummaries(String from, String to);
  Future<String?> firstLogDay();
  Future<List<Goal>> goals();
  Future<void> insertGoal(Goal goal);
  Future<void> softDeleteGoal(String id);
}

class ProgressLocalDataSourceImpl implements ProgressLocalDataSource {
  ProgressLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  static const _liveRuns = 'deleted = 0 AND draft = 0';
  static const _runKcal = 'COALESCE(kcal_override, kcal)';

  static const _burnRows =
      '''
    SELECT day, kcal AS k FROM ${Tables.gymSessions} WHERE deleted = 0 AND day BETWEEN ? AND ?
    UNION ALL
    SELECT day, $_runKcal AS k FROM ${Tables.runs} WHERE $_liveRuns AND day BETWEEN ? AND ?''';

  @override
  Future<DayTotals> dayTotals(String day) async {
    final row = (await _database.db.rawQuery(
      '''
      SELECT
        (SELECT COALESCE(SUM(kcal), 0) FROM ${Tables.gymSessions} WHERE day = ?1 AND deleted = 0) AS gym_kcal,
        (SELECT COUNT(*) FROM ${Tables.gymSessions} WHERE day = ?1 AND deleted = 0) AS gym_count,
        (SELECT COALESCE(SUM($_runKcal), 0) FROM ${Tables.runs} WHERE day = ?1 AND $_liveRuns) AS run_kcal,
        (SELECT COUNT(*) FROM ${Tables.runs} WHERE day = ?1 AND $_liveRuns) AS run_count,
        (SELECT COALESCE(SUM(ml), 0) FROM ${Tables.water} WHERE day = ?1 AND deleted = 0) AS water_ml,
        (SELECT COALESCE(SUM(grams), 0) FROM ${Tables.protein} WHERE day = ?1 AND deleted = 0) AS protein_g
      ''',
      [day],
    )).single;
    return DayTotals(
      day: day,
      gymKcal: row['gym_kcal']! as int,
      gymCount: row['gym_count']! as int,
      runKcal: row['run_kcal']! as int,
      runCount: row['run_count']! as int,
      waterMl: row['water_ml']! as int,
      proteinG: (row['protein_g']! as num).toDouble(),
    );
  }

  @override
  Future<Map<String, int>> burnByDay(String from, String to) async {
    final rows = await _database.db.rawQuery('SELECT day, SUM(k) AS kcal FROM ($_burnRows) GROUP BY day', [
      from,
      to,
      from,
      to,
    ]);
    return {for (final r in rows) r['day']! as String: r['kcal']! as int};
  }

  @override
  Future<Set<String>> activeDays(String from, String to) async {
    final rows = await _database.db.rawQuery('SELECT DISTINCT day FROM ($_burnRows)', [from, to, from, to]);
    return {for (final r in rows) r['day']! as String};
  }

  @override
  Future<List<ActivityItem>> activities(String from, String to) async {
    final db = _database.db;
    final gym = await db.query(Tables.gymSessions, where: 'deleted = 0 AND day BETWEEN ? AND ?', whereArgs: [from, to]);
    final runs = await db.query(Tables.runs, where: '$_liveRuns AND day BETWEEN ? AND ?', whereArgs: [from, to]);
    return [for (final r in gym) r.toGymActivity(), for (final r in runs) r.toRunActivity()]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
  }

  @override
  Future<Map<String, DayTotals>> daySummaries(String from, String to) async {
    final rows = await _database.db.rawQuery(
      '''
      SELECT day, SUM(gk) AS gk, SUM(gc) AS gc, SUM(rk) AS rk, SUM(rc) AS rc, SUM(w) AS w, SUM(pr) AS pr FROM (
        SELECT day, kcal AS gk, 1 AS gc, 0 AS rk, 0 AS rc, 0 AS w, 0 AS pr
          FROM ${Tables.gymSessions} WHERE deleted = 0 AND day BETWEEN ?1 AND ?2
        UNION ALL SELECT day, 0, 0, $_runKcal, 1, 0, 0 FROM ${Tables.runs} WHERE $_liveRuns AND day BETWEEN ?1 AND ?2
        UNION ALL SELECT day, 0, 0, 0, 0, ml, 0 FROM ${Tables.water} WHERE deleted = 0 AND day BETWEEN ?1 AND ?2
        UNION ALL SELECT day, 0, 0, 0, 0, 0, grams FROM ${Tables.protein} WHERE deleted = 0 AND day BETWEEN ?1 AND ?2
      ) GROUP BY day''',
      [from, to],
    );
    return {
      for (final r in rows)
        r['day']! as String: DayTotals(
          day: r['day']! as String,
          gymKcal: (r['gk']! as num).toInt(),
          gymCount: (r['gc']! as num).toInt(),
          runKcal: (r['rk']! as num).toInt(),
          runCount: (r['rc']! as num).toInt(),
          waterMl: (r['w']! as num).toInt(),
          proteinG: (r['pr']! as num).toDouble(),
        ),
    };
  }

  @override
  Future<String?> firstLogDay() async {
    final row = (await _database.db.rawQuery('''
      SELECT MIN(day) AS d FROM (
        SELECT MIN(day) AS day FROM ${Tables.gymSessions} WHERE deleted = 0
        UNION ALL SELECT MIN(day) FROM ${Tables.runs} WHERE $_liveRuns
        UNION ALL SELECT MIN(day) FROM ${Tables.water} WHERE deleted = 0
        UNION ALL SELECT MIN(day) FROM ${Tables.protein} WHERE deleted = 0
      )''')).single;
    return row['d'] as String?;
  }

  @override
  Future<List<Goal>> goals() async {
    final rows = await _database.db.query(Tables.goals, where: 'deleted = 0', orderBy: 'created_at');
    return [
      for (final r in rows)
        Goal(
          id: r['sync_id']! as String,
          kind: GoalKind.values.firstWhere((k) => k.name == r['kind'], orElse: () => GoalKind.gymSessions),
          period: r['period'] == 'month' ? GoalPeriod.month : GoalPeriod.week,
          target: (r['target']! as num).toDouble(),
        ),
    ];
  }

  @override
  Future<void> insertGoal(Goal g) => _database.db.insert(Tables.goals, {
    'sync_id': g.id,
    'kind': g.kind.name,
    'period': g.period.name,
    'target': g.target,
    'created_at': DateTime.now().millisecondsSinceEpoch,
    'updated_at': DateTime.now().millisecondsSinceEpoch,
    'deleted': 0,
    'synced': 0,
  });

  @override
  Future<void> softDeleteGoal(String id) => _database.db.update(
    Tables.goals,
    {'deleted': 1, 'synced': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
    where: 'sync_id = ?',
    whereArgs: [id],
  );
}
