typedef EffortSpan = ({double seconds, int end});

class TrackAnalysis {
  const TrackAnalysis({required this.efforts, required this.paceBins});

  final Map<int, EffortSpan> efforts;
  final Map<int, double> paceBins;
}

class RunAnalysis {
  const RunAnalysis({
    required this.runId,
    required this.startedAt,
    required this.distanceM,
    required this.movingSec,
    required this.efforts,
    required this.paceBins,
    this.effort,
  });

  final String runId;
  final DateTime startedAt;
  final int distanceM;
  final int movingSec;
  final Map<int, EffortSpan> efforts;
  final Map<int, double> paceBins;
  final int? effort;

  double get km => distanceM / 1000;
  double get paceSecPerKm => distanceM == 0 ? 0 : movingSec / km;
}
