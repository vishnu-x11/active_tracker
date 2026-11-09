import '../../../../core/dates.dart';
import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../entities/run.dart';
import '../repositories/run_repository.dart';
import 'run_metrics.dart';

class SaveRun {
  const SaveRun(this._repository, {required this.newId, DateTime Function()? now}) : _now = now ?? DateTime.now;

  final RunRepository _repository;
  final String Function() newId;
  final DateTime Function() _now;

  static String? problem({
    required String title,
    required double? km,
    required int? seconds,
    required DateTime startedAt,
    required String kcalText,
    required DateTime now,
  }) {
    if (title.trim().isEmpty) return 'Give the run a title';
    if (km == null) return 'Enter a distance above 0 km';
    if (seconds == null) return 'Enter the moving time, e.g. 29:35';
    if (seconds > 24 * 3600) return 'A run can be at most 24 hours';
    if (seconds / km < 120) return 'That pace is faster than 2:00 /km. Check the distance and time';
    if (startedAt.isAfter(now)) return "The start time can't be in the future";
    if (kcalText.trim().isNotEmpty && (int.tryParse(kcalText.trim()) ?? 0) <= 0) {
      return 'Calories must be a whole number above 0';
    }
    return null;
  }

  Future<Result<Run>> call({
    String? id,
    required String title,
    required RunType type,
    required RunSource source,
    required String kmText,
    required String timeText,
    required DateTime startedAt,
    required double weightKg,
    int? effort,
    String kcalText = '',
    int? elevationM,
  }) async {
    final km = RunMetrics.km(kmText), secs = RunMetrics.seconds(timeText);
    final issue = problem(title: title, km: km, seconds: secs, startedAt: startedAt, kcalText: kcalText, now: _now());
    if (issue != null) return Err(ValidationFailure(issue));
    final estimate = runKcal(weightKg: weightKg, km: km!);
    final override = int.tryParse(kcalText.trim());
    final run = Run(
      id: id ?? newId(),
      day: dayKey(startedAt),
      startedAt: startedAt,
      title: title.trim(),
      type: type,
      source: source,
      distanceM: (km * 1000).round(),
      movingSec: secs!,
      weightKg: weightKg,
      kcal: estimate,
      elevationM: elevationM,
      effort: effort,
      kcalOverride: override == null || override == estimate ? null : override,
    );
    return switch (await _repository.save(run)) {
      Ok() => Ok(run),
      Err(:final failure) => Err(failure),
    };
  }
}
