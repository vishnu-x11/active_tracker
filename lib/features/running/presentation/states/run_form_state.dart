import '../../../../core/formulas/formulas.dart';
import '../../domain/entities/run.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../domain/use_cases/save_run.dart';

class RunFormState {
  const RunFormState({
    required this.day,
    required this.startMinute,
    this.source = RunSource.manual,
    this.isDraft = false,
    this.title = 'Morning Run',
    this.type = RunType.outdoor,
    this.kmText = '',
    this.timeText = '',
    this.paceText = '',
    this.effort = 3,
    this.kcalText = '',
    this.elevationM,
    this.weightKg = 75,
    this.loading = false,
    this.showErrors = false,
    this.saving = false,
    this.error,
    this.savedId,
  });

  final DateTime day;
  final int startMinute;
  final RunSource source;

  final bool isDraft;
  final String title;
  final RunType type;
  final String kmText;
  final String timeText;
  final String paceText;
  final int effort;

  final String kcalText;
  final int? elevationM;
  final double weightKg;
  final bool loading;
  final bool showErrors;
  final bool saving;
  final String? error;
  final String? savedId;

  bool get locked => source == RunSource.gps;
  double? get km => RunMetrics.km(kmText);
  int? get seconds => RunMetrics.seconds(timeText);
  DateTime get startedAt => day.add(Duration(minutes: startMinute));
  int get estimate => km == null ? 0 : runKcal(weightKg: weightKg, km: km!);
  int get kcalShown => int.tryParse(kcalText.trim()) ?? estimate;
  bool get usesOwnKcal => (int.tryParse(kcalText.trim()) ?? estimate) != estimate;
  double? get speedKmh => km == null || seconds == null ? null : km! / (seconds! / 3600);

  String? problem(DateTime now) => showErrors
      ? SaveRun.problem(title: title, km: km, seconds: seconds, startedAt: startedAt, kcalText: kcalText, now: now)
      : null;

  RunFormState copyWith({
    DateTime? day,
    int? startMinute,
    RunSource? source,
    bool? isDraft,
    String? title,
    RunType? type,
    String? kmText,
    String? timeText,
    String? paceText,
    int? effort,
    String? kcalText,
    int? Function()? elevationM,
    double? weightKg,
    bool? loading,
    bool? showErrors,
    bool? saving,
    String? Function()? error,
    String? savedId,
  }) => RunFormState(
    day: day ?? this.day,
    startMinute: startMinute ?? this.startMinute,
    source: source ?? this.source,
    isDraft: isDraft ?? this.isDraft,
    title: title ?? this.title,
    type: type ?? this.type,
    kmText: kmText ?? this.kmText,
    timeText: timeText ?? this.timeText,
    paceText: paceText ?? this.paceText,
    effort: effort ?? this.effort,
    kcalText: kcalText ?? this.kcalText,
    elevationM: elevationM != null ? elevationM() : this.elevationM,
    weightKg: weightKg ?? this.weightKg,
    loading: loading ?? this.loading,
    showErrors: showErrors ?? this.showErrors,
    saving: saving ?? this.saving,
    error: error != null ? error() : this.error,
    savedId: savedId ?? this.savedId,
  );

  @override
  bool operator ==(Object other) =>
      other is RunFormState &&
      other.day == day &&
      other.startMinute == startMinute &&
      other.source == source &&
      other.isDraft == isDraft &&
      other.title == title &&
      other.type == type &&
      other.kmText == kmText &&
      other.timeText == timeText &&
      other.paceText == paceText &&
      other.effort == effort &&
      other.kcalText == kcalText &&
      other.elevationM == elevationM &&
      other.weightKg == weightKg &&
      other.loading == loading &&
      other.showErrors == showErrors &&
      other.saving == saving &&
      other.error == error &&
      other.savedId == savedId;

  @override
  int get hashCode => Object.hashAll([
    day,
    startMinute,
    source,
    isDraft,
    title,
    type,
    kmText,
    timeText,
    paceText,
    effort,
    kcalText,
    elevationM,
    weightKg,
    loading,
    showErrors,
    saving,
    error,
    savedId,
  ]);
}
