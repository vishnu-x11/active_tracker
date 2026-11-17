import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/formulas/formulas.dart';
import '../../../../core/result.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/run_settings.dart';
import '../../domain/use_cases/run_insights.dart';
import '../../domain/use_cases/run_metrics.dart';
import '../../running_routes.dart';
import '../notifiers/run_recorder_notifier.dart';
import '../providers.dart';
import '../states/run_recorder_state.dart';
import 'location_gate.dart';

const zoneColors = [
  Color(0xFF8FA3B8),
  Color(0xFF4FB4FF),
  Color(0xFF14B87A),
  Color(0xFFFFB15C),
  Color(0xFFFF7A3A),
  Color(0xFFE8343C),
];

String raceClock(double seconds) => RunMetrics.clock(seconds.round());

String signedClock(double seconds) => RunMetrics.clock(seconds.abs().round());

String paceText(double secPerKm) => '${formatPace(secPerKm)} /km';

String zoneTime(double seconds) {
  final s = seconds.round();
  if (s >= 3600) return '${s ~/ 3600}h ${(s % 3600) ~/ 60}m';
  if (s >= 60) return '${s ~/ 60}m ${s % 60}s';
  return '${s}s';
}

class ChangeChip extends StatelessWidget {
  const ChangeChip({super.key, required this.text, required this.good, this.down = true});

  final String text;
  final bool good;
  final bool down;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: good ? p.goodBg : p.text.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            down ? Icons.arrow_drop_down_rounded : Icons.arrow_drop_up_rounded,
            size: 18,
            color: good ? p.goodFg : p.sub,
          ),
          Text(text, style: AppText.tab.copyWith(fontSize: 12, color: good ? p.goodFg : p.sub)),
        ],
      ),
    );
  }
}

Future<void> startSuggestedWorkout(BuildContext context, WidgetRef ref, SuggestedWorkout s) async {
  final messenger = ScaffoldMessenger.of(context);
  if (ref.exists(runRecorderProvider)) {
    final rec = ref.read(runRecorderProvider);
    if (rec.status == RecorderStatus.ready) {
      ref.read(runRecorderProvider.notifier).updateSettings(rec.settings.copyWith(workout: s.workout));
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Finish the current recording first.')));
    }
  } else {
    final current = (await ref.read(getRunSettingsProvider)()).valueOrNull ?? const RunSettings();
    final saved = await ref.read(saveRunSettingsProvider)(current.copyWith(workout: s.workout));
    if (saved case Err(:final failure)) {
      messenger.showSnackBar(SnackBar(content: Text(failure.message)));
      return;
    }
  }
  if (context.mounted && await ensureRunLocation(context) && context.mounted) await context.push(RunRoutes.record);
}
