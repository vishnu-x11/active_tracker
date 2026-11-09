enum GoalKind {
  gymSessions('Gym sessions', 'sessions', 1),
  runDistance('Run distance', 'km', 1),
  activeBurn('Active burn', 'kcal', 50),
  proteinDays('Protein days', 'days', 1),
  waterDays('Water days', 'days', 1);

  const GoalKind(this.label, this.unit, this.step);
  final String label;
  final String unit;

  final int step;

  bool get decimals => this == runDistance;

  double get start => switch (this) {
    gymSessions => 4,
    runDistance => 20,
    activeBurn => 3000,
    proteinDays || waterDays => 5,
  };

  String title(double target) {
    final t = target % 1 == 0 ? target.toStringAsFixed(0) : target.toStringAsFixed(1);
    return switch (this) {
      gymSessions => '$t gym sessions',
      runDistance => 'Run $t km',
      activeBurn => 'Burn $t kcal',
      proteinDays => 'Hit protein $t days',
      waterDays => 'Hit water $t days',
    };
  }
}

enum GoalPeriod { week, month }

class Goal {
  const Goal({required this.id, required this.kind, required this.period, required this.target});

  final String id;
  final GoalKind kind;
  final GoalPeriod period;
  final double target;

  @override
  bool operator ==(Object other) =>
      other is Goal && other.id == id && other.kind == kind && other.period == period && other.target == target;

  @override
  int get hashCode => Object.hash(id, kind, period, target);
}
