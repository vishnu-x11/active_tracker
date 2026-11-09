class ReminderSettings {
  const ReminderSettings({
    this.waterOn = true,
    this.waterFrom = 9 * 60,
    this.waterTo = 21 * 60,
    this.proteinOn = true,
    this.proteinAt = 20 * 60,
    this.workoutOn = true,
    this.workoutAt = 18 * 60,
    this.workoutDays = const {1, 3, 4},
    this.streakOn = true,
    this.streakAt = 21 * 60,
    this.weeklyOn = true,
    this.weeklyAt = 8 * 60,
  });

  final bool waterOn;
  final int waterFrom;
  final int waterTo;
  final bool proteinOn;
  final int proteinAt;
  final bool workoutOn;
  final int workoutAt;
  final Set<int> workoutDays;
  final bool streakOn;
  final int streakAt;
  final bool weeklyOn;
  final int weeklyAt;

  int get activeCount => [waterOn, proteinOn, workoutOn, streakOn, weeklyOn].where((b) => b).length;

  String? get problem {
    if (waterOn && waterTo <= waterFrom) return 'Water nudges: the end time must be after the start time.';
    if (workoutOn && workoutDays.isEmpty) return 'Pick at least one day for workout reminders.';
    return null;
  }

  ReminderSettings copyWith({
    bool? waterOn,
    int? waterFrom,
    int? waterTo,
    bool? proteinOn,
    int? proteinAt,
    bool? workoutOn,
    int? workoutAt,
    Set<int>? workoutDays,
    bool? streakOn,
    int? streakAt,
    bool? weeklyOn,
    int? weeklyAt,
  }) => ReminderSettings(
    waterOn: waterOn ?? this.waterOn,
    waterFrom: waterFrom ?? this.waterFrom,
    waterTo: waterTo ?? this.waterTo,
    proteinOn: proteinOn ?? this.proteinOn,
    proteinAt: proteinAt ?? this.proteinAt,
    workoutOn: workoutOn ?? this.workoutOn,
    workoutAt: workoutAt ?? this.workoutAt,
    workoutDays: workoutDays ?? this.workoutDays,
    streakOn: streakOn ?? this.streakOn,
    streakAt: streakAt ?? this.streakAt,
    weeklyOn: weeklyOn ?? this.weeklyOn,
    weeklyAt: weeklyAt ?? this.weeklyAt,
  );

  @override
  bool operator ==(Object other) =>
      other is ReminderSettings &&
      other.waterOn == waterOn &&
      other.waterFrom == waterFrom &&
      other.waterTo == waterTo &&
      other.proteinOn == proteinOn &&
      other.proteinAt == proteinAt &&
      other.workoutOn == workoutOn &&
      other.workoutAt == workoutAt &&
      other.workoutDays.length == workoutDays.length &&
      other.workoutDays.containsAll(workoutDays) &&
      other.streakOn == streakOn &&
      other.streakAt == streakAt &&
      other.weeklyOn == weeklyOn &&
      other.weeklyAt == weeklyAt;

  @override
  int get hashCode => Object.hash(
    waterOn,
    waterFrom,
    waterTo,
    proteinOn,
    proteinAt,
    workoutOn,
    workoutAt,
    Object.hashAllUnordered(workoutDays),
    streakOn,
    streakAt,
    weeklyOn,
    weeklyAt,
  );
}

class PlannedReminder {
  const PlannedReminder({required this.id, required this.at, required this.title, required this.body});

  final int id;
  final DateTime at;
  final String title;
  final String body;

  @override
  String toString() => '$id $at $title';
}

typedef TodayStatus = ({
  int waterMl,
  int? waterTarget,
  double proteinG,
  int? proteinTarget,
  bool workedOut,
  int streak,
});
