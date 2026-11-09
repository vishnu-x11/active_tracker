import '../../../progress/progress.dart';

class ActivityState {
  const ActivityState({this.filter = ActivityFilter.all, this.allDays = true});

  final ActivityFilter filter;

  final bool allDays;

  ActivityState copyWith({ActivityFilter? filter, bool? allDays}) =>
      ActivityState(filter: filter ?? this.filter, allDays: allDays ?? this.allDays);

  @override
  bool operator ==(Object other) => other is ActivityState && other.filter == filter && other.allDays == allDays;

  @override
  int get hashCode => Object.hash(filter, allDays);
}
