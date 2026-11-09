import 'package:flutter/material.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'buttons.dart';
import 'glass.dart';

class FormHeader extends StatelessWidget {
  const FormHeader({super.key, required this.title, required this.onBack, this.trailing});

  final String title;
  final VoidCallback onBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GlassIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack, tooltip: 'Back'),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.title.copyWith(color: context.palette.text),
          ),
        ),
        if (trailing case final t?)
          ConstrainedBox(constraints: const BoxConstraints(minWidth: 44), child: t)
        else
          const SizedBox(width: 44),
      ],
    );
  }
}

class PickerField extends StatelessWidget {
  const PickerField({super.key, required this.label, required this.value, required this.icon, required this.onTap});

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Semantics(
      button: true,
      label: '$label, $value',
      excludeSemantics: true,
      child: Glass(
        kind: GlassKind.control,
        radius: 18,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 14, 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppText.number.copyWith(fontWeight: FontWeight.w600, fontSize: 17, color: p.text),
                      ),
                    ],
                  ),
                ),
                Icon(icon, size: 18, color: p.sub),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class FormSection extends StatelessWidget {
  const FormSection(this.title, {super.key, this.note});

  final String title;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Expanded(
            child: Text(title, style: AppText.section.copyWith(color: p.text)),
          ),
          if (note != null)
            Text(
              note!,
              style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
            ),
        ],
      ),
    );
  }
}

class SaveBar extends StatelessWidget {
  const SaveBar({super.key, required this.button, this.error});

  final Widget button;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Glass(
      kind: GlassKind.bar,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (error != null)
                Semantics(
                  liveRegion: true,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      error!,
                      textAlign: TextAlign.center,
                      style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
                    ),
                  ),
                ),
              button,
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDelete(BuildContext context, {required String what}) async {
  final p = context.palette;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: p.pageTop,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text('Delete $what?', style: AppText.title.copyWith(color: p.text)),
      content: Text("This can't be undone.", style: AppText.body.copyWith(color: p.sub)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('Cancel', style: TextStyle(color: p.text)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text('Delete', style: TextStyle(color: p.danger)),
        ),
      ],
    ),
  );
  return ok ?? false;
}
