import '../../../../core/result.dart';
import '../entities/activity_item.dart';
import '../repositories/progress_repository.dart';

class GetActivities {
  const GetActivities(this._repository);

  final ProgressRepository _repository;

  Future<Result<List<ActivityItem>>> call(String from, String to, {ActivityFilter filter = ActivityFilter.all}) async =>
      switch (await _repository.activities(from, to)) {
        Ok(:final value) => Ok([
          for (final a in value)
            if (filter.allows(a.type)) a,
        ]),
        Err(:final failure) => Err(failure),
      };
}
