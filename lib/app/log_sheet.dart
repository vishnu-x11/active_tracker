import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/dates.dart';
import '../core/theme/app_palette.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/buttons.dart';
import '../core/widgets/glass.dart';

typedef LogOption = ({
  String title,
  String hint,
  IconData icon,
  List<Color> colors,
  String? route,
  bool live,
  Future<bool> Function(BuildContext context)? gate,
});

class LogSheet extends StatelessWidget {
  const LogSheet({super.key, required this.options});

  final List<LogOption> options;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    return Align(
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
        child: Glass(
          kind: GlassKind.bar,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(color: p.hair, borderRadius: BorderRadius.circular(3)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${weekdayLong(now)}, ${now.day} ${monthLong[now.month - 1]}',
                              style: AppText.small.copyWith(fontWeight: FontWeight.w500, color: p.sub),
                            ),
                            Text('Log for Today', style: AppText.display.copyWith(fontSize: 22, color: p.text)),
                          ],
                        ),
                      ),
                      GlassIconButton(icon: Icons.close_rounded, tooltip: 'Close', onPressed: () => context.pop()),
                    ],
                  ),
                  const SizedBox(height: 18),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    padding: EdgeInsets.zero,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.5,
                    children: [for (final o in options.where((o) => !o.live)) _Option(option: o)],
                  ),
                  for (final o in options.where((o) => o.live)) ...[
                    const SizedBox(height: 12),
                    _Option(option: o, wide: true),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    'Saved for today. Change the date in each form.',
                    textAlign: TextAlign.center,
                    style: AppText.small.copyWith(fontSize: 12, color: p.sub),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.option, this.wide = false});

  final LogOption option;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final o = option;
    final enabled = o.route != null;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                o.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardTitle.copyWith(fontSize: 15, color: p.text),
              ),
            ),
            if (!enabled) ...[const SizedBox(width: 6), Text('Soon', style: AppText.tab.copyWith(color: p.sub))],
          ],
        ),
        const SizedBox(height: 3),
        Text(
          o.hint,
          maxLines: wide ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.small.copyWith(fontSize: 12, color: p.sub),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: Glass(
        kind: GlassKind.control,
        radius: 22,
        blur: false,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: enabled
              ? () async {
                  if (o.gate case final gate? when !await gate(context)) return;
                  if (context.mounted) context.pushReplacement(o.route!);
                }
              : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: wide
                ? Row(
                    children: [
                      IconTile(icon: o.icon, colors: o.colors, size: 38),
                      const SizedBox(width: 12),
                      Expanded(child: text),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconTile(icon: o.icon, colors: o.colors, size: 36),
                      text,
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

class LogSheetPage extends CustomTransitionPage<void> {
  LogSheetPage({required List<LogOption> options, super.key})
    : super(
        opaque: false,
        barrierDismissible: true,
        barrierColor: const Color(0x73040610),
        transitionDuration: const Duration(milliseconds: 260),
        child: LogSheet(options: options),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position: Tween(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
}
