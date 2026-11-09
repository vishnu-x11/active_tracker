class DayTotals {
  const DayTotals({
    required this.day,
    this.gymKcal = 0,
    this.runKcal = 0,
    this.gymCount = 0,
    this.runCount = 0,
    this.waterMl = 0,
    this.proteinG = 0,
  });

  final String day;
  final int gymKcal;
  final int runKcal;
  final int gymCount;
  final int runCount;
  final int waterMl;
  final double proteinG;

  int get burnKcal => gymKcal + runKcal;
  int get workouts => gymCount + runCount;

  bool get isWorkoutDay => workouts > 0;

  @override
  bool operator ==(Object other) =>
      other is DayTotals &&
      other.day == day &&
      other.gymKcal == gymKcal &&
      other.runKcal == runKcal &&
      other.gymCount == gymCount &&
      other.runCount == runCount &&
      other.waterMl == waterMl &&
      other.proteinG == proteinG;

  @override
  int get hashCode => Object.hash(day, gymKcal, runKcal, gymCount, runCount, waterMl, proteinG);
}
