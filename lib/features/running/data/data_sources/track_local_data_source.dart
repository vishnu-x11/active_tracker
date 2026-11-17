import 'package:sqflite/sqflite.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/run.dart';
import '../../domain/entities/run_analysis.dart';
import '../../domain/entities/track_point.dart';
import '../models/run_model.dart';
import '../models/track_analysis_model.dart';

abstract interface class TrackLocalDataSource {
  Future<void> saveDraft(Run draft, List<TrackPoint> points);
  Future<List<TrackPoint>> points(String runId);

  Future<List<Run>> gpsRuns();

  Future<Map<String, TrackAnalysis>> analyses(int version);
  Future<void> saveAnalyses(Map<String, TrackAnalysis> analyses, int version);
}

class TrackLocalDataSourceImpl implements TrackLocalDataSource {
  TrackLocalDataSourceImpl(this._database);

  final AppDatabase _database;

  @override
  Future<void> saveDraft(Run draft, List<TrackPoint> points) => _database.db.transaction((txn) async {
    await txn.insert(Tables.runs, draft.toRow(DateTime.now().millisecondsSinceEpoch));
    final batch = txn.batch();
    for (final (i, p) in points.indexed) {
      batch.insert(Tables.runPoints, {
        'run_sync_id': draft.id,
        'seq': i,
        'lat': p.lat,
        'lng': p.lng,
        'alt': p.alt,
        't': p.t,
        'segment': p.segment,
      });
    }
    await batch.commit(noResult: true);
  });

  @override
  Future<List<TrackPoint>> points(String runId) async {
    final rows = await _database.db.query(
      Tables.runPoints,
      where: 'run_sync_id = ?',
      whereArgs: [runId],
      orderBy: 'seq',
    );
    return [
      for (final r in rows)
        TrackPoint(
          lat: (r['lat']! as num).toDouble(),
          lng: (r['lng']! as num).toDouble(),
          alt: (r['alt'] as num?)?.toDouble(),
          t: r['t']! as int,
          segment: r['segment']! as int,
        ),
    ];
  }

  @override
  Future<List<Run>> gpsRuns() async {
    final rows = await _database.db.query(
      Tables.runs,
      where: "source = 'gps' AND draft = 0 AND deleted = 0",
      orderBy: 'started_at',
    );
    return [for (final r in rows) r.toRun()];
  }

  @override
  Future<Map<String, TrackAnalysis>> analyses(int version) async {
    final rows = await _database.db.query(Tables.runAnalysis, where: 'version = ?', whereArgs: [version]);
    return {for (final r in rows) r['run_sync_id']! as String: r.toTrackAnalysis()};
  }

  @override
  Future<void> saveAnalyses(Map<String, TrackAnalysis> analyses, int version) async {
    final batch = _database.db.batch();
    for (final e in analyses.entries) {
      batch.insert(Tables.runAnalysis, e.value.toRow(e.key, version), conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }
}
