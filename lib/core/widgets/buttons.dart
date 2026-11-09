import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class GradientButton extends StatelessWidget {
  const GradientButton({super.key, required this.label, required this.onPressed, this.trailing, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final String? trailing;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final enabled = onPressed != null;
    final text = Text.rich(
      TextSpan(
        text: label,
        children: [
          if (trailing != null)
            TextSpan(
              text: '  ·  $trailing',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
      ),
      style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: enabled ? Colors.white : p.sub),
    );
    final content = SizedBox(
      height: 56,
      child: Center(
        child: busy
            ? const SizedBox.square(
                dimension: 22,
                child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
              )
            : text,
      ),
    );
    if (!enabled) return Glass(kind: GlassKind.control, radius: 20, child: content);
    return Semantics(
      button: true,
      label: busy ? '$label, in progress' : null,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: Metric.cta, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(color: Metric.cta.last.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 10)),
            ],
          ),
          child: InkWell(borderRadius: BorderRadius.circular(20), onTap: busy ? null : onPressed, child: content),
        ),
      ),
    );
  }
}

class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Glass(
        kind: GlassKind.control,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onPressed,
              child: Icon(icon, size: 21, color: context.palette.text),
            ),
          ),
        ),
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({super.key, required this.icon, required this.colors, this.size = 36});

  final IconData icon;
  final List<Color> colors;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 3),
        gradient: LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight),
        boxShadow: [BoxShadow(color: colors.last.withValues(alpha: 0.35), blurRadius: 14, offset: const Offset(0, 6))],
      ),
      child: Icon(icon, size: size * 0.56, color: Colors.white),
    );
  }
}
