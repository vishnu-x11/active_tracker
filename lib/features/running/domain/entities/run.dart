enum RunType {
  outdoor('Outdoor'),
  treadmill('Treadmill'),
  trail('Trail'),
  other('Other');

  const RunType(this.label);
  final String label;
}

enum RunSource { manual, gps }

const effortNames = ['Easy', 'Moderate', 'Steady', 'Hard', 'Max'];

class Run {
  const Run({
    required this.id,
    required this.day,
    required this.startedAt,
    required this.title,
    required this.type,
    required this.source,
    required this.distanceM,
    required this.movingSec,
    required this.weightKg,
    required this.kcal,
    this.elevationM,
    this.effort,
    this.kcalOverride,
    this.draft = false,
  });

  final String id;
  final String day;
  final DateTime startedAt;
  final String title;
  final RunType type;
  final RunSource source;
  final int distanceM;
  final int movingSec;
  final double weightKg;
  final int kcal;
  final int? elevationM;
  final int? effort;
  final int? kcalOverride;
  final bool draft;

  double get km => distanceM / 1000;
  int get kcalShown => kcalOverride ?? kcal;
  double get paceSecPerKm => distanceM == 0 ? 0 : movingSec / km;
  double get speedKmh => movingSec == 0 ? 0 : km / (movingSec / 3600);
  DateTime get endedAt => startedAt.add(Duration(seconds: movingSec));

  @override
  bool operator ==(Object other) =>
      other is Run &&
      other.id == id &&
      other.day == day &&
      other.startedAt == startedAt &&
      other.title == title &&
      other.type == type &&
      other.source == source &&
      other.distanceM == distanceM &&
      other.movingSec == movingSec &&
      other.weightKg == weightKg &&
      other.kcal == kcal &&
      other.elevationM == elevationM &&
      other.effort == effort &&
      other.kcalOverride == kcalOverride &&
      other.draft == draft;

  @override
  int get hashCode => Object.hash(
    id,
    day,
    startedAt,
    title,
    type,
    source,
    distanceM,
    movingSec,
    weightKg,
    kcal,
    elevationM,
    effort,
    kcalOverride,
    draft,
  );
}
