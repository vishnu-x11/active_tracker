import 'package:flutter/material.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/buttons.dart';
import '../../../../core/widgets/glass.dart';

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
    this.footer,
    this.onBack,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? footer;

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      body: PageBackdrop(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: [
              SizedBox(
                height: 44,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: onBack == null
                      ? null
                      : GlassIconButton(icon: Icons.arrow_back_rounded, onPressed: onBack!, tooltip: 'Back'),
                ),
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: IconTile(icon: icon, colors: Metric.cta, size: 56),
              ),
              const SizedBox(height: 16),
              Text(title, style: AppText.display.copyWith(fontSize: 32, color: p.text)),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: AppText.body.copyWith(fontSize: 15, height: 1.45, fontWeight: FontWeight.w400, color: p.sub),
              ),
              const SizedBox(height: 24),
              ...children,
              if (footer != null) ...[const SizedBox(height: 24), Center(child: footer)],
            ],
          ),
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  const AuthFooterLink({super.key, required this.lead, required this.action, required this.onTap});

  final String lead;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(lead, style: AppText.body.copyWith(color: p.sub)),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(minimumSize: const Size(44, 44), foregroundColor: p.accentText),
          child: Text(
            action,
            style: AppText.body.copyWith(fontWeight: FontWeight.w700, color: p.accentText),
          ),
        ),
      ],
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final line = Expanded(child: Container(height: 1, color: p.hair));
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              'or',
              style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.sub),
            ),
          ),
          line,
        ],
      ),
    );
  }
}
