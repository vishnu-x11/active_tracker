class WeekBurn {
  const WeekBurn({required this.monday, required this.days, required this.previousTotal});

  final String monday;

  final List<int> days;
  final int previousTotal;

  int get total => days.fold(0, (a, b) => a + b);

  int? get changePct => previousTotal == 0 ? null : ((total - previousTotal) * 100 / previousTotal).round();

  @override
  bool operator ==(Object other) =>
      other is WeekBurn &&
      other.monday == monday &&
      other.previousTotal == previousTotal &&
      other.days.length == days.length &&
      Iterable<int>.generate(days.length).every((i) => other.days[i] == days[i]);

  @override
  int get hashCode => Object.hash(monday, previousTotal, Object.hashAll(days));
}
