import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';

class OnboardingFrame extends StatelessWidget {
  const OnboardingFrame({
    super.key,
    required this.step,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    required this.button,
    this.onBack,
    this.action,
  });

  final int step;
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget button;
  final VoidCallback? onBack;

  final Widget? action;

  static const steps = 3;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    if (onBack != null) ...[
                      GlassIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack!, tooltip: 'Back'),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: Semantics(
                        label: 'Step $step of $steps',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('STEP $step OF $steps', style: AppText.eyebrow.copyWith(color: p.sub)),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                for (var i = 1; i <= steps; i++) ...[
                                  if (i > 1) const SizedBox(width: 6),
                                  Expanded(
                                    child: _Segment(done: i <= step, current: i == step),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    ?action,
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconTile(icon: icon, colors: Metric.cta, size: 56),
                    ),
                    const SizedBox(height: 16),
                    Text(title, style: AppText.display.copyWith(fontSize: 32, color: p.text)),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: AppText.body.copyWith(
                        fontSize: 15,
                        height: 1.45,
                        fontWeight: FontWeight.w400,
                        color: p.sub,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...children,
                  ],
                ),
              ),
              Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), child: button),
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({required this.done, required this.current});

  final bool done;
  final bool current;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 6,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(3),
        gradient: done ? const LinearGradient(colors: Metric.cta) : null,
        color: done ? null : context.palette.hair,
        boxShadow: current
            ? [BoxShadow(color: Metric.cta.last.withValues(alpha: 0.45), blurRadius: 8, offset: const Offset(0, 2))]
            : null,
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
    child: Text(text.toUpperCase(), style: AppText.eyebrow.copyWith(color: context.palette.sub)),
  );
}
