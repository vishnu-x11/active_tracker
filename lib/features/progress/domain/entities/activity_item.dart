enum ActivityType { gym, run }

enum ActivityFilter {
  all,
  gym,
  run;

  bool allows(ActivityType t) => this == all || (this == gym ? t == ActivityType.gym : t == ActivityType.run);
}

class ActivityItem {
  const ActivityItem({
    required this.id,
    required this.type,
    required this.day,
    required this.startedAt,
    required this.title,
    required this.kcal,
    this.durationMin,
    this.intensity,
    this.distanceM,
    this.movingSec,
    this.fromGps = false,
  });

  final String id;
  final ActivityType type;
  final String day;
  final DateTime startedAt;
  final String title;
  final int kcal;

  final int? durationMin;
  final String? intensity;

  final int? distanceM;
  final int? movingSec;
  final bool fromGps;

  double get km => (distanceM ?? 0) / 1000;

  @override
  bool operator ==(Object other) =>
      other is ActivityItem &&
      other.id == id &&
      other.type == type &&
      other.day == day &&
      other.startedAt == startedAt &&
      other.title == title &&
      other.kcal == kcal &&
      other.durationMin == durationMin &&
      other.intensity == intensity &&
      other.distanceM == distanceM &&
      other.movingSec == movingSec &&
      other.fromGps == fromGps;

  @override
  int get hashCode =>
      Object.hash(id, type, day, startedAt, title, kcal, durationMin, intensity, distanceM, movingSec, fromGps);
}
