import 'package:flutter/material.dart';

import '../../../../core/dates.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/use_cases/training_log.dart';

class LogDot extends StatelessWidget {
  const LogDot({super.key, required this.day, this.onTap, this.scale = 1});

  final LogDay day;
  final VoidCallback? onTap;
  final double scale;

  static const sizes = [7.0, 18.0, 28.0, 38.0];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final step = TrainingLog.dotStep(day.minutes);
    final size = sizes[step] * scale;
    final colors = day.run && day.gym
        ? const [Metric.runDot, Metric.burnDot]
        : day.run
        ? const [Metric.runDot, Metric.runDot]
        : const [Metric.burnDot, Metric.burnDot];
    final what = [if (day.run) 'run', if (day.gym) 'gym'].join(' and ');
    return Semantics(
      button: step > 0 && onTap != null,
      label:
          '${weekdayLong(day.date)} ${day.date.day} ${monthLong[day.date.month - 1]}'
          '${step == 0 ? ', rest' : ', ${day.minutes} min $what'}${day.today ? ', today' : ''}',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: step == 0 ? null : onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: sizes.last * scale,
              child: Center(
                child: Container(
                  width: size,
                  height: size,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: step == 0 ? p.text.withValues(alpha: day.future ? 0.06 : 0.16) : null,
                    gradient: step == 0
                        ? null
                        : LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
                  ),
                  child: step >= 2 && scale >= 1
                      ? FittedBox(
                          child: Padding(
                            padding: const EdgeInsets.all(3),
                            child: Text(
                              TrainingLog.clock(day.minutes),
                              style: AppText.tab.copyWith(fontSize: 10, color: Colors.white),
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(
              height: 10,
              child: day.today ? Icon(Icons.arrow_drop_up_rounded, size: 16, color: p.accentText) : null,
            ),
          ],
        ),
      ),
    );
  }
}
