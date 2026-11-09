import 'dart:async';

import 'package:active_tracker/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_driver/flutter_driver.dart' as driver;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

// Performance gate from the plan (section 8): p90 frame build under 8 ms and under 1% janky frames.
// Run on a device in profile mode, signed in (the app opens on Home):
//   flutter drive --profile --driver=test_driver/perf_driver.dart --target=integration_test/perf_test.dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> gate(String name, Future<void> Function() action) async {
    final timeline = await binding.traceTimeline(action);
    // traceTimeline returns the VM service type; the summariser takes flutter_driver's.
    final summary = driver.TimelineSummary.summarize(driver.Timeline.fromJson(timeline.toJson()));
    binding.reportData = {...?binding.reportData, name: summary.summaryJson};
    final json = summary.summaryJson;
    final p90 = (json['90th_percentile_frame_build_time_millis'] as num).toDouble();
    final frames = (json['frame_count'] as num).toInt();
    final missed = (json['missed_frame_build_budget_count'] as num).toInt();
    expect(p90, lessThan(8), reason: '$name: p90 frame build time');
    expect(frames == 0 ? 0 : missed / frames, lessThan(0.01), reason: '$name: janky frame ratio');
  }

  testWidgets('frame budget: tabs, Activity filter, date strip', (tester) async {
    unawaited(app.main());
    await tester.pumpAndSettle(const Duration(seconds: 3));

    await gate('tab_switch', () async {
      for (var round = 0; round < 5; round++) {
        for (final tab in ['Activity', 'Progress', 'Profile', 'Home']) {
          await tester.tap(find.text(tab).last);
          await tester.pumpAndSettle();
        }
      }
    });

    await tester.tap(find.text('Activity').last);
    await tester.pumpAndSettle();

    // The All / Gym / Runs switch (reported slow on 2026-11-06; list rows now draw without live blur).
    await gate('activity_filter', () async {
      for (var round = 0; round < 5; round++) {
        for (final f in ['Gym', 'Runs', 'All']) {
          await tester.tap(find.text(f).last);
          await tester.pumpAndSettle();
        }
      }
    });

    await gate('date_strip_scroll', () async {
      final strip = find.byType(ListView).first;
      for (var i = 0; i < 3; i++) {
        await tester.fling(strip, const Offset(400, 0), 1500);
        await tester.pumpAndSettle();
        await tester.fling(strip, const Offset(-400, 0), 1500);
        await tester.pumpAndSettle();
      }
    });
  });
}
