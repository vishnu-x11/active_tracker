import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/dates.dart';
import '../../../../core/widgets/app_dialog.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../notifiers/run_recorder_notifier.dart';
import '../providers.dart';

class UnfinishedRunPrompt extends ConsumerStatefulWidget {
  const UnfinishedRunPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UnfinishedRunPrompt> createState() => _UnfinishedRunPromptState();
}

class _UnfinishedRunPromptState extends ConsumerState<UnfinishedRunPrompt> {
  late final AppLifecycleListener _life;
  bool _asking = false;

  @override
  void initState() {
    super.initState();
    _life = AppLifecycleListener(onResume: _check);
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  @override
  void dispose() {
    _life.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    if (_asking || !mounted || ref.exists(runRecorderProvider)) return;
    _asking = true;
    try {
      await _ask();
    } finally {
      _asking = false;
    }
  }

  Future<void> _ask() async {
    final run = (await ref.read(getUnfinishedRecordingProvider)()).valueOrNull;
    if (run == null || !mounted || ref.exists(runRecorderProvider)) return;
    final km = (run.meters / 1000).toStringAsFixed(2);
    final started = DateTime.fromMillisecondsSinceEpoch(run.points.first.t);
    final when = dateOnly(started) == dateOnly(DateTime.now()) ? 'today' : 'on ${shortDate(started)}';
    final resume = await showAppDialog(
      context,
      icon: Icons.directions_run_rounded,
      title: 'Resume your unfinished run?',
      message: '$km km · ${RunMetrics.clock(run.movingMs ~/ 1000)} recorded $when and not saved yet.',
      cancel: 'Discard',
      confirm: 'Resume',
      dismissible: false,
    );
    if (!mounted) return;
    if (resume ?? false) {
      await context.push(RunRoutes.record);
    } else {
      await ref.read(clearRecordingProvider)();
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
