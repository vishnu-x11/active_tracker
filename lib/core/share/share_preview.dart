import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_palette.dart';
import '../theme/app_theme.dart';
import '../widgets/buttons.dart';
import '../widgets/glass.dart';
import 'image_sharer.dart';

Future<void> showSharePreview(BuildContext context, {required Widget card, required String name, String? text}) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: const Color(0x73040610),
      builder: (_) => SharePreview(card: card, name: name, text: text),
    );

class SharePreview extends ConsumerStatefulWidget {
  const SharePreview({super.key, required this.card, required this.name, this.text});

  final Widget card;
  final String name;
  final String? text;

  @override
  ConsumerState<SharePreview> createState() => _SharePreviewState();
}

class _SharePreviewState extends ConsumerState<SharePreview> {
  final _boundary = GlobalKey();
  bool _busy = false;
  String? _error;

  Future<void> _share() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final box = _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await box.toImage(pixelRatio: 3);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      await ref.read(imageSharerProvider).sharePng(data!.buffer.asUint8List(), name: widget.name, text: widget.text);
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _error = "Couldn't share the image. Please try again.");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Share', style: AppText.display.copyWith(fontSize: 24, color: p.text)),
                  ),
                  GlassIconButton(icon: Icons.close_rounded, tooltip: 'Close', onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 14),
              Flexible(
                child: FittedBox(
                  child: RepaintBoundary(key: _boundary, child: widget.card),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: p.danger),
                ),
              ],
              const SizedBox(height: 14),
              GradientButton(label: 'Share image', busy: _busy, onPressed: _share),
            ],
          ),
        ),
      ),
    );
  }
}

class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({super.key, required this.colors, required this.child});

  final List<Color> colors;
  final Widget child;

  static const size = Size(360, 450);

  @override
  Widget build(BuildContext context) => SizedBox.fromSize(
    size: size,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF141726), Color(0xFF06070C)],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned(
              right: -80,
              top: -80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [colors.last.withValues(alpha: 0.55), colors.last.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: DefaultTextStyle(
                style: const TextStyle(fontFamily: 'Inter', color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: child),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            gradient: const LinearGradient(colors: Metric.cta),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active Tracker',
                          style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class ShareStat extends StatelessWidget {
  const ShareStat({super.key, required this.value, required this.label, this.unit});

  final String value;
  final String label;
  final String? unit;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text.rich(
        TextSpan(
          text: value,
          children: [
            if (unit != null)
              TextSpan(
                text: ' $unit',
                style: AppText.small.copyWith(color: Colors.white60),
              ),
          ],
        ),
        style: AppText.number.copyWith(fontSize: 22, color: Colors.white),
      ),
      Text(label, style: AppText.tab.copyWith(fontSize: 12, color: Colors.white60)),
    ],
  );
}
