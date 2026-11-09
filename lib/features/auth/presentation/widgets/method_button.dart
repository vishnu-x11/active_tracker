import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/glass.dart';

class MethodButton extends StatelessWidget {
  const MethodButton({
    super.key,
    required this.leading,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  final Widget leading;
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      kind: GlassKind.control,
      radius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: busy ? null : onPressed,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (busy)
                  SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: p.text))
                else
                  leading,
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body.copyWith(fontSize: 16, fontWeight: FontWeight.w600, color: p.text),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleMark extends StatelessWidget {
  const GoogleMark({super.key});

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const SweepGradient(
        colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
      ).createShader(r),
      child: const Text(
        'G',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, height: 1),
      ),
    );
  }
}
