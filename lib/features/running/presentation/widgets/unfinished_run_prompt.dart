import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_palette.dart';
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
    final p = context.palette;
    final km = (run.meters / 1000).toStringAsFixed(2);
    final resume = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (c) => AlertDialog(
        backgroundColor: p.pageTop,
        title: const Text('Resume your unfinished run?'),
        content: Text('$km km · ${RunMetrics.clock(run.movingMs ~/ 1000)} recorded before the app closed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: Text('Discard', style: TextStyle(color: p.danger)),
          ),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Resume')),
        ],
      ),
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
