import '../../domain/entities/run.dart';

extension RunRowToEntity on Map<String, Object?> {
  Run toRun() => Run(
    id: this['sync_id']! as String,
    day: this['day']! as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(this['started_at']! as int),
    title: this['title']! as String,
    type: RunType.values.firstWhere((t) => t.name == this['run_type'], orElse: () => RunType.other),
    source: this['source'] == 'gps' ? RunSource.gps : RunSource.manual,
    distanceM: this['distance_m']! as int,
    movingSec: this['moving_sec']! as int,
    weightKg: (this['weight_kg']! as num).toDouble(),
    kcal: this['kcal']! as int,
    elevationM: this['elevation_m'] as int?,
    effort: this['effort'] as int?,
    kcalOverride: this['kcal_override'] as int?,
    draft: this['draft'] == 1,
  );
}

extension RunToRow on Run {
  Map<String, Object?> toRow(int updatedAt) => {
    'sync_id': id,
    'day': day,
    'started_at': startedAt.millisecondsSinceEpoch,
    'title': title,
    'run_type': type.name,
    'source': source.name,
    'draft': draft ? 1 : 0,
    'distance_m': distanceM,
    'moving_sec': movingSec,
    'elevation_m': elevationM,
    'effort': effort,
    'weight_kg': weightKg,
    'kcal': kcal,
    'kcal_override': kcalOverride,
    'updated_at': updatedAt,
    'deleted': 0,
    'synced': 0,
  };
}
