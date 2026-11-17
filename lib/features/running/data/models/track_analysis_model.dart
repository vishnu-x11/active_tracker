import 'dart:convert';

import '../../domain/entities/run_analysis.dart';

extension TrackAnalysisToRow on TrackAnalysis {
  Map<String, Object?> toRow(String runId, int version) => {
    'run_sync_id': runId,
    'version': version,
    'efforts': jsonEncode({
      for (final e in efforts.entries) '${e.key}': [e.value.seconds, e.value.end],
    }),
    'pace_bins': jsonEncode({for (final e in paceBins.entries) '${e.key}': e.value}),
  };
}

extension TrackAnalysisRow on Map<String, Object?> {
  TrackAnalysis toTrackAnalysis() => TrackAnalysis(
    efforts: {
      for (final e in (jsonDecode(this['efforts']! as String) as Map).entries)
        int.parse(e.key as String): (
          seconds: ((e.value as List)[0] as num).toDouble(),
          end: ((e.value as List)[1] as num).toInt(),
        ),
    },
    paceBins: {
      for (final e in (jsonDecode(this['pace_bins']! as String) as Map).entries)
        int.parse(e.key as String): (e.value as num).toDouble(),
    },
  );
}
