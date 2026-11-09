import '../entities/run_settings.dart';

abstract final class Speech {
  static String duration(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    String unit(int n, String w) => '$n $w${n == 1 ? '' : 's'}';
    return [
      if (h > 0) unit(h, 'hour'),
      if (m > 0) unit(m, 'minute'),
      if (h == 0 && (s > 0 || m == 0)) unit(s, 'second'),
    ].join(' ');
  }

  static String pace(double secPerKm) {
    final s = secPerKm.round();
    final m = '${s ~/ 60} ${s ~/ 60 == 1 ? 'minute' : 'minutes'}';
    return s % 60 == 0 ? '$m per kilometre' : '$m ${s % 60} per kilometre';
  }

  static String distance(double meters) {
    if (meters < 1000) return '${meters.round()} metres';
    final km = (meters / 100).round() / 10;
    final text = km == km.roundToDouble() ? '${km.round()}' : km.toStringAsFixed(1);
    return '$text ${text == '1' ? 'kilometre' : 'kilometres'}';
  }

  static String split({required double meters, required int seconds}) {
    final parts = ['${distance(meters)}.', 'Time ${duration(seconds)}.'];
    if (meters >= 100) parts.add('Average pace ${pace(seconds / (meters / 1000))}.');
    return parts.join(' ');
  }
}

class SplitCues {
  SplitCues(this.everyM, {double fromM = 0}) : _next = everyM <= 0 ? 0 : (fromM ~/ everyM + 1) * everyM;

  final int everyM;
  int _next;

  String? check({required double meters, required int seconds}) {
    if (everyM <= 0 || meters < _next) return null;
    final mark = (meters ~/ everyM) * everyM;
    _next = mark + everyM;
    return Speech.split(meters: mark.toDouble(), seconds: seconds);
  }
}

typedef CoachView = ({String title, String? detail, bool done});

class WorkoutCoach {
  WorkoutCoach(this.workout) : steps = workout.steps;

  final RunWorkout workout;
  final List<WorkoutStep> steps;

  int _index = -1;
  double _startM = 0;
  int _startS = 0;
  int? _lastPaceCueS;

  static const paceSlack = 10;
  static const paceCueEvery = 60;

  int get index => _index;
  bool get done => workout.kind == WorkoutKind.intervals && _index >= steps.length;
  WorkoutStep? get step => _index >= 0 && _index < steps.length ? steps[_index] : null;

  List<String> update({required double meters, required int seconds, double? pace}) {
    switch (workout.kind) {
      case WorkoutKind.free:
        return const [];
      case WorkoutKind.targetPace:
        if (_index < 0) {
          _index = 0;
          _lastPaceCueS = seconds;
          return ['Target pace ${Speech.pace(workout.targetPaceSec.toDouble())}.'];
        }
        if (pace == null || seconds - (_lastPaceCueS ?? 0) < paceCueEvery) return const [];
        final off = pace - workout.targetPaceSec;
        if (off.abs() <= paceSlack) return const [];
        _lastPaceCueS = seconds;
        return [off > 0 ? 'Speed up. Pace ${Speech.pace(pace)}.' : 'Ease off. Pace ${Speech.pace(pace)}.'];
      case WorkoutKind.intervals:
        final out = <String>[];
        if (_index < 0) {
          _enter(0, meters, seconds);
          out.add(_say(step!));
        }
        while (true) {
          final s = step;
          if (s == null || !_reached(s, meters, seconds)) break;
          _enter(_index + 1, meters, seconds);
          out.add(step == null ? 'Workout complete.' : _say(step!));
        }
        return out;
    }
  }

  void _enter(int i, double meters, int seconds) {
    _index = i;
    _startM = meters;
    _startS = seconds;
  }

  bool _reached(WorkoutStep s, double meters, int seconds) =>
      (s.meters != null && meters - _startM >= s.meters!) || (s.seconds != null && seconds - _startS >= s.seconds!);

  String _say(WorkoutStep s) => switch (s.kind) {
    StepKind.warmup => 'Warm up for ${Speech.duration(s.seconds!)}.',
    StepKind.work => 'Rep ${s.rep} of ${workout.reps}. Run ${Speech.distance(s.meters!.toDouble())}.',
    StepKind.rest => 'Rest for ${Speech.duration(s.seconds!)}.',
    StepKind.cooldown => 'Intervals done. Cool down, then finish when ready.',
  };

  CoachView? view({required double meters, required int seconds, double? pace}) {
    switch (workout.kind) {
      case WorkoutKind.free:
        return null;
      case WorkoutKind.targetPace:
        final t = _clock(workout.targetPaceSec);
        if (pace == null) return (title: 'Target $t /km', detail: null, done: false);
        final off = (pace - workout.targetPaceSec).round();
        final detail = off.abs() <= paceSlack ? 'On pace' : (off > 0 ? '${off}s slower' : '${-off}s faster');
        return (title: 'Target $t /km', detail: detail, done: false);
      case WorkoutKind.intervals:
        final s = step;
        if (s == null) {
          return (title: _index < 0 ? 'Intervals ready' : 'Workout complete', detail: null, done: _index >= 0);
        }
        final left = s.meters != null
            ? '${(s.meters! - (meters - _startM)).clamp(0, s.meters!).round()} m left'
            : (s.seconds != null ? '${_clock((s.seconds! - (seconds - _startS)).clamp(0, s.seconds!))} left' : null);
        final title = switch (s.kind) {
          StepKind.warmup => 'Warm-up',
          StepKind.work => 'Rep ${s.rep}/${workout.reps} · Run',
          StepKind.rest => 'Rep ${s.rep}/${workout.reps} · Rest',
          StepKind.cooldown => 'Cool-down',
        };
        return (title: title, detail: left, done: false);
    }
  }

  static String _clock(int s) => '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
}
