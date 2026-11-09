import '../../domain/entities/activity_item.dart';

extension GymRowToActivity on Map<String, Object?> {
  ActivityItem toGymActivity() => ActivityItem(
    id: this['sync_id']! as String,
    type: ActivityType.gym,
    day: this['day']! as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(this['started_at']! as int),
    title: this['title']! as String,
    kcal: this['kcal']! as int,
    durationMin: this['duration_min']! as int,
    intensity: this['intensity']! as String,
  );

  ActivityItem toRunActivity() => ActivityItem(
    id: this['sync_id']! as String,
    type: ActivityType.run,
    day: this['day']! as String,
    startedAt: DateTime.fromMillisecondsSinceEpoch(this['started_at']! as int),
    title: this['title']! as String,
    kcal: (this['kcal_override'] ?? this['kcal'])! as int,
    distanceM: this['distance_m']! as int,
    movingSec: this['moving_sec']! as int,
    fromGps: this['source'] == 'gps',
  );
}
