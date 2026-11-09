import 'package:active_tracker/core/result.dart';
import 'package:active_tracker/features/profile/domain/entities/body_stats_rules.dart';
import 'package:active_tracker/features/profile/domain/entities/profile.dart';
import 'package:active_tracker/features/profile/domain/use_cases/save_body_stats.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fakes.dart';

void main() {
  group('BodyStatsRules', () {
    test('weight and height ranges, with the design messages', () {
      expect(BodyStatsRules.weight(''), 'Enter your weight');
      expect(BodyStatsRules.weight('29'), 'Weight must be 30 to 250 kg');
      expect(BodyStatsRules.weight('75,5'), isNull);
      expect(BodyStatsRules.height('231'), 'Height must be 120 to 230 cm');
      expect(BodyStatsRules.height('178'), isNull);
    });

    test('age is optional', () {
      expect(BodyStatsRules.age(''), isNull);
      expect(BodyStatsRules.age('12'), 'Age must be 13 to 100');
    });

    test('burn target: any whole number above 0, no upper limit', () {
      expect(BodyStatsRules.burnTarget('0'), 'Use a whole number above 0');
      expect(BodyStatsRules.burnTarget('12.5'), 'Use a whole number above 0');
      expect(BodyStatsRules.burnTarget('1'), isNull);
      expect(BodyStatsRules.burnTarget('25000'), isNull);
    });
  });

  test('SaveBodyStats parses and saves, keeping default ratios', () async {
    final repo = FakeProfileRepository();
    final r = await SaveBodyStats(repo)(
      uid: 'u1',
      weight: '75.5',
      height: '178',
      age: '',
      sex: Sex.female,
      burnTarget: '650',
    );
    final p = r.valueOrNull!;
    expect(p.weightKg, 75.5);
    expect(p.age, isNull);
    expect(p.burnTargetKcal, 650);
    expect(p.proteinGPerKg, 1.6);
    expect(repo.saved['u1'], p);
  });

  test('SaveBodyStats refuses invalid input without saving', () async {
    final repo = FakeProfileRepository();
    final r = await SaveBodyStats(repo)(uid: 'u1', weight: '75', height: '178', age: '', sex: null, burnTarget: '0');
    expect((r as Err).failure, isA<ValidationFailure>());
    expect(repo.saved, isEmpty);
  });
}
