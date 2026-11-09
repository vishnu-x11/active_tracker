class ProteinEntry {
  const ProteinEntry({required this.id, required this.day, required this.at, required this.grams, this.food});

  final String id;
  final String day;
  final DateTime at;
  final double grams;

  final String? food;

  @override
  bool operator ==(Object other) =>
      other is ProteinEntry &&
      other.id == id &&
      other.day == day &&
      other.at == at &&
      other.grams == grams &&
      other.food == food;

  @override
  int get hashCode => Object.hash(id, day, at, grams, food);
}

class Food {
  const Food({this.id, required this.name, required this.serving, required this.grams});

  final String? id;
  final String name;
  final String serving;
  final double grams;

  static const starters = [
    Food(name: 'Whey protein', serving: '1 scoop', grams: 24),
    Food(name: 'Eggs', serving: '3 whole', grams: 18),
    Food(name: 'Chicken breast', serving: '100 g', grams: 31),
    Food(name: 'Paneer', serving: '100 g', grams: 18),
  ];

  @override
  bool operator ==(Object other) =>
      other is Food && other.id == id && other.name == name && other.serving == serving && other.grams == grams;

  @override
  int get hashCode => Object.hash(id, name, serving, grams);
}
