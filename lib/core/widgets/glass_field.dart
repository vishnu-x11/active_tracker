import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import 'glass.dart';

class GlassField extends StatelessWidget {
  const GlassField({
    super.key,
    required this.label,
    required this.controller,
    this.onChanged,
    this.unit,
    this.hint,
    this.error,
    this.keyboardType,
    this.inputFormatters,
    this.obscureText = false,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.suffix,
    this.valueStyle,
    this.autofocus = false,
    this.textAlign = TextAlign.start,
  });

  final String label;
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String? unit;
  final String? hint;

  final String? error;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final bool obscureText;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  final Widget? suffix;
  final TextStyle? valueStyle;
  final bool autofocus;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final hasError = error != null;
    final field = Glass(
      kind: GlassKind.control,
      radius: 18,
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: AppText.eyebrow.copyWith(letterSpacing: 0, fontWeight: FontWeight.w500, color: p.sub),
                ),
                const SizedBox(height: 2),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        onChanged: onChanged,
                        keyboardType: keyboardType,
                        inputFormatters: inputFormatters,
                        obscureText: obscureText,
                        autofillHints: autofillHints,
                        textInputAction: textInputAction,
                        onSubmitted: onSubmitted,
                        autofocus: autofocus,
                        textAlign: textAlign,
                        cursorColor: Metric.cta.last,
                        style: (valueStyle ?? AppText.number.copyWith(fontWeight: FontWeight.w600)).copyWith(
                          color: p.text,
                        ),
                        decoration: InputDecoration.collapsed(
                          hintText: hint,
                          hintStyle: AppText.body.copyWith(fontSize: 17, color: p.sub.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                    if (unit != null) ...[
                      const SizedBox(width: 4),
                      Text(unit!, style: AppText.body.copyWith(color: p.sub)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ],
            ),
          ),
          ?suffix,
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: hasError ? Border.all(color: p.danger, width: 2) : null,
          ),
          child: field,
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
            child: Text(
              error!,
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
            ),
          ),
      ],
    );
  }
}

class FormMessage extends StatelessWidget {
  const FormMessage({super.key, required this.text, this.good = false});

  final String text;

  final bool good;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fg = good ? p.goodFg : p.danger;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: good ? p.goodBg : Metric.alert.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(good ? Icons.check_circle_rounded : Icons.error_rounded, size: 18, color: fg),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: fg),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
