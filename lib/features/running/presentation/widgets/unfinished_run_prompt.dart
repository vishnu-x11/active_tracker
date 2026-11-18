import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/widgets/app_dialog.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../providers.dart';

class UnfinishedRunPrompt extends ConsumerStatefulWidget {
  const UnfinishedRunPrompt({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<UnfinishedRunPrompt> createState() => _UnfinishedRunPromptState();
}

class _UnfinishedRunPromptState extends ConsumerState<UnfinishedRunPrompt> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _check());
  }

  Future<void> _check() async {
    final run = await ref.read(unfinishedRecordingProvider.future);
    if (run == null || !mounted) return;
    final km = (run.meters / 1000).toStringAsFixed(2);
    final resume = await showAppDialog(
      context,
      icon: Icons.directions_run_rounded,
      title: 'Resume your unfinished run?',
      message: '$km km · ${RunMetrics.clock(run.movingMs ~/ 1000)} recorded before the app closed.',
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
