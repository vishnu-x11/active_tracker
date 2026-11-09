import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/glass.dart';
import '../core/widgets/layout.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const bottomInset = tabBarInset;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: PageBackdrop(child: navigationShell),
      bottomNavigationBar: _FloatingTabBar(
        index: navigationShell.currentIndex,
        onTab: (i) => navigationShell.goBranch(i, initialLocation: i == navigationShell.currentIndex),
        onLog: () => context.push('/log'),
      ),
    );
  }
}

class _FloatingTabBar extends StatelessWidget {
  const _FloatingTabBar({required this.index, required this.onTab, required this.onLog});

  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onLog;

  static const _tabs = [
    (Icons.home_outlined, 'Home'),
    (Icons.monitor_heart_outlined, 'Activity'),
    (Icons.bar_chart_rounded, 'Progress'),
    (Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    Widget tab(int i) {
      final (icon, label) = _tabs[i];
      final selected = i == index;
      final color = selected ? p.accentText : p.tabIdle;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          label: label,
          excludeSemantics: true,
          child: InkResponse(
            onTap: () => onTab(i),
            radius: 32,
            child: SizedBox(
              height: 56,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, size: 24, color: color),
                    const SizedBox(height: 4),
                    Text(label, style: AppText.tab.copyWith(color: color)),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Glass(
        kind: GlassKind.bar,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              tab(0),
              tab(1),
              Expanded(
                child: Center(child: _LogButton(onPressed: onLog)),
              ),
              tab(2),
              tab(3),
            ],
          ),
        ),
      ),
    );
  }
}

class _LogButton extends StatelessWidget {
  const _LogButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Log activity',
      child: Material(
        color: Colors.transparent,
        child: Ink(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(colors: Metric.cta, begin: Alignment.topLeft, end: Alignment.bottomRight),
            boxShadow: [
              BoxShadow(color: Metric.cta.last.withValues(alpha: 0.45), blurRadius: 22, offset: const Offset(0, 10)),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: onPressed,
            child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
          ),
        ),
      ),
    );
  }
}
