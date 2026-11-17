import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../data/data_sources/location_source.dart';
import '../providers.dart';

enum _Choice { act, cancel }

Future<bool> ensureRunLocation(BuildContext context) async {
  final source = ProviderScope.containerOf(context, listen: false).read(locationSourceProvider);
  while (true) {
    final problem = await source.ensureAccess();
    if (problem == null) return true;
    if (!context.mounted) return false;
    final choice = await showDialog<_Choice>(
      context: context,
      builder: (_) => _LocationDialog(problem: problem),
    );
    if (choice != _Choice.act || !context.mounted) return false;
    if (problem == LocationProblem.denied) continue;
    final back = _nextResume();
    await (problem == LocationProblem.serviceOff ? source.openLocationSettings() : source.openSettings());
    await back;
    if (!context.mounted) return false;
  }
}

Future<void> _nextResume() {
  final done = Completer<void>();
  late final AppLifecycleListener listener;
  listener = AppLifecycleListener(
    onResume: () {
      listener.dispose();
      if (!done.isCompleted) done.complete();
    },
  );
  return done.future.timeout(const Duration(minutes: 5), onTimeout: () => listener.dispose());
}

class _LocationDialog extends StatelessWidget {
  const _LocationDialog({required this.problem});

  final LocationProblem problem;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (title, intro, steps, action) = switch (problem) {
      LocationProblem.serviceOff => (
        'Turn on location',
        'Your phone\'s location is off, so GPS can\'t track your route, distance or pace.',
        const ['Tap Open settings below.', 'Switch on Use location.', 'Come back here and your run screen opens.'],
        'Open settings',
      ),
      LocationProblem.denied => (
        'Allow location access',
        'Active Tracker needs your location to draw your route and measure distance and pace.',
        const ['Tap Allow below.', 'Choose While using the app.', 'Pick Precise location for the best accuracy.'],
        'Allow',
      ),
      LocationProblem.deniedForever => (
        'Location access is blocked',
        'Location was turned off for Active Tracker, so GPS runs can\'t record.',
        const [
          'Tap Open settings below.',
          'Open Permissions, then Location.',
          'Choose Allow only while using the app.',
          'Come back here and your run screen opens.',
        ],
        'Open settings',
      ),
    };
    return AlertDialog(
      backgroundColor: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Icon(Icons.location_on_rounded, color: Metric.cta.last, size: 32),
      title: Text(title, style: AppText.title.copyWith(color: p.text)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(intro, style: AppText.body.copyWith(color: p.sub)),
          const SizedBox(height: 14),
          for (final (i, step) in steps.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(colors: Metric.cta),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${i + 1}',
                      style: AppText.small.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(step, style: AppText.body.copyWith(color: p.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, _Choice.cancel), child: const Text('Not now')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Metric.cta.last),
          onPressed: () => Navigator.pop(context, _Choice.act),
          child: Text(action),
        ),
      ],
    );
  }
}
