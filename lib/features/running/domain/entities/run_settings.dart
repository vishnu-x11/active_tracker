enum WorkoutKind { free, targetPace, intervals }

enum StepKind { warmup, work, rest, cooldown }

class WorkoutStep {
  const WorkoutStep(this.kind, {this.meters, this.seconds, this.rep});

  final StepKind kind;
  final int? meters;
  final int? seconds;
  final int? rep;

  bool get open => meters == null && seconds == null;

  @override
  bool operator ==(Object other) =>
      other is WorkoutStep &&
      other.kind == kind &&
      other.meters == meters &&
      other.seconds == seconds &&
      other.rep == rep;

  @override
  int get hashCode => Object.hash(kind, meters, seconds, rep);
}

class RunWorkout {
  const RunWorkout({
    this.kind = WorkoutKind.free,
    this.targetPaceSec = 360,
    this.reps = 6,
    this.workM = 400,
    this.restSec = 90,
    this.warmupMin = 10,
  });

  final WorkoutKind kind;
  final int targetPaceSec;
  final int reps;
  final int workM;
  final int restSec;
  final int warmupMin;

  static const paceRange = (min: 150, max: 900);
  static const repsRange = (min: 1, max: 30);
  static const workRange = (min: 100, max: 5000);
  static const restRange = (min: 15, max: 600);
  static const warmupRange = (min: 0, max: 30);

  List<WorkoutStep> get steps => kind != WorkoutKind.intervals
      ? const []
      : [
          if (warmupMin > 0) WorkoutStep(StepKind.warmup, seconds: warmupMin * 60),
          for (var i = 1; i <= reps; i++) ...[
            WorkoutStep(StepKind.work, meters: workM, rep: i),
            if (i < reps) WorkoutStep(StepKind.rest, seconds: restSec, rep: i),
          ],
          const WorkoutStep(StepKind.cooldown),
        ];

  RunWorkout copyWith({WorkoutKind? kind, int? targetPaceSec, int? reps, int? workM, int? restSec, int? warmupMin}) =>
      RunWorkout(
        kind: kind ?? this.kind,
        targetPaceSec: (targetPaceSec ?? this.targetPaceSec).clamp(paceRange.min, paceRange.max),
        reps: (reps ?? this.reps).clamp(repsRange.min, repsRange.max),
        workM: (workM ?? this.workM).clamp(workRange.min, workRange.max),
        restSec: (restSec ?? this.restSec).clamp(restRange.min, restRange.max),
        warmupMin: (warmupMin ?? this.warmupMin).clamp(warmupRange.min, warmupRange.max),
      );

  Map<String, Object?> toMap() => {
    'kind': kind.name,
    'pace': targetPaceSec,
    'reps': reps,
    'work': workM,
    'rest': restSec,
    'warmup': warmupMin,
  };

  static RunWorkout fromMap(Map<String, Object?> m) => const RunWorkout().copyWith(
    kind: WorkoutKind.values.where((k) => k.name == m['kind']).firstOrNull,
    targetPaceSec: m['pace'] as int?,
    reps: m['reps'] as int?,
    workM: m['work'] as int?,
    restSec: m['rest'] as int?,
    warmupMin: m['warmup'] as int?,
  );

  @override
  bool operator ==(Object other) =>
      other is RunWorkout &&
      other.kind == kind &&
      other.targetPaceSec == targetPaceSec &&
      other.reps == reps &&
      other.workM == workM &&
      other.restSec == restSec &&
      other.warmupMin == warmupMin;

  @override
  int get hashCode => Object.hash(kind, targetPaceSec, reps, workM, restSec, warmupMin);
}

class RunSettings {
  const RunSettings({
    this.autoPause = true,
    this.voice = true,
    this.splitEveryM = 1000,
    this.workout = const RunWorkout(),
  });

  final bool autoPause;
  final bool voice;
  final int splitEveryM;
  final RunWorkout workout;

  static const splitOptions = [0, 500, 1000, 2000];

  bool get autoPauseActive => autoPause && workout.kind != WorkoutKind.intervals;

  RunSettings copyWith({bool? autoPause, bool? voice, int? splitEveryM, RunWorkout? workout}) => RunSettings(
    autoPause: autoPause ?? this.autoPause,
    voice: voice ?? this.voice,
    splitEveryM: splitEveryM ?? this.splitEveryM,
    workout: workout ?? this.workout,
  );

  Map<String, Object?> toMap() => {
    'autoPause': autoPause,
    'voice': voice,
    'split': splitEveryM,
    'workout': workout.toMap(),
  };

  static RunSettings fromMap(Map<String, Object?> m) => RunSettings(
    autoPause: m['autoPause'] as bool? ?? true,
    voice: m['voice'] as bool? ?? true,
    splitEveryM: splitOptions.contains(m['split']) ? m['split']! as int : 1000,
    workout: m['workout'] is Map
        ? RunWorkout.fromMap((m['workout']! as Map).cast<String, Object?>())
        : const RunWorkout(),
  );

  @override
  bool operator ==(Object other) =>
      other is RunSettings &&
      other.autoPause == autoPause &&
      other.voice == voice &&
      other.splitEveryM == splitEveryM &&
      other.workout == workout;

  @override
  int get hashCode => Object.hash(autoPause, voice, splitEveryM, workout);
}
