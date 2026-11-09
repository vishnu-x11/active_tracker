class WaterEntry {
  const WaterEntry({required this.id, required this.day, required this.at, required this.ml});

  final String id;
  final String day;
  final DateTime at;
  final int ml;

  @override
  bool operator ==(Object other) =>
      other is WaterEntry && other.id == id && other.day == day && other.at == at && other.ml == ml;

  @override
  int get hashCode => Object.hash(id, day, at, ml);
}

enum Drink {
  glass('Glass', 250),
  bottle('Bottle', 500),
  large('Large bottle', 750),
  custom('Custom', null);

  const Drink(this.label, this.ml);
  final String label;
  final int? ml;
}

enum WaterUnit { ml, l }
