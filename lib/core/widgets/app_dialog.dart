import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';

Future<bool?> showAppDialog(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String message,
  required String cancel,
  required String confirm,
  bool danger = false,
  bool dismissible = true,
}) => showDialog<bool>(
  context: context,
  barrierDismissible: dismissible,
  builder: (c) {
    final p = c.palette;
    final accent = danger ? p.danger : Metric.cta.last;
    return AlertDialog(
      backgroundColor: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      icon: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
        child: Icon(icon, color: accent, size: 30),
      ),
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: AppText.title.copyWith(color: p.text),
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: AppText.body.copyWith(color: p.sub),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      actions: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  foregroundColor: p.text,
                  side: BorderSide(color: p.hair),
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(c, false),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(cancel, maxLines: 1)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  backgroundColor: accent,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                ),
                onPressed: () => Navigator.pop(c, true),
                child: FittedBox(fit: BoxFit.scaleDown, child: Text(confirm, maxLines: 1)),
              ),
            ),
          ],
        ),
      ],
    );
  },
);
