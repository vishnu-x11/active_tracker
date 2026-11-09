import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/app_palette.dart';

enum GlassKind { card, control, bar }

class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.kind = GlassKind.card,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.borderRadius,
    this.blur,
  });

  final Widget child;

  final bool? blur;
  final GlassKind kind;
  final double radius;
  final EdgeInsetsGeometry padding;

  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final br = borderRadius ?? BorderRadius.circular(radius);
    final (colors, sigma) = switch (kind) {
      GlassKind.card => (p.glass, 28.0),
      GlassKind.control => (p.glassHi, 22.0),
      GlassKind.bar => (p.bar, 34.0),
    };
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: br,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: colors),
        border: Border.all(color: p.edge),
      ),
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Material(
            type: MaterialType.transparency,
            child: Padding(padding: padding, child: child),
          ),
          Positioned(
            left: 14,
            right: 14,
            top: 0,
            height: 1,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [p.highlight.withValues(alpha: 0), p.highlight, p.highlight.withValues(alpha: 0)],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    return RepaintBoundary(
      child: DecoratedBox(
        decoration: BoxDecoration(borderRadius: br, boxShadow: p.shadow),
        child: (blur ?? kind == GlassKind.bar)
            ? ClipRRect(
                borderRadius: br,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: sigma / 2, sigmaY: sigma / 2),
                  child: surface,
                ),
              )
            : surface,
      ),
    );
  }
}

class PageBackdrop extends StatelessWidget {
  const PageBackdrop({super.key, required this.child, this.orbs});

  final Widget child;

  final List<Orb>? orbs;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.pageTop, p.pageBottom],
              ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                for (final orb in orbs ?? p.orbs)
                  Align(
                    alignment: orb.alignment,
                    child: SizedBox.square(
                      dimension: orb.radius * 2,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [orb.color, orb.color.withValues(alpha: 0)],
                            stops: const [0, 0.72],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class TapGlass extends StatelessWidget {
  const TapGlass({
    super.key,
    required this.child,
    required this.onTap,
    this.kind = GlassKind.card,
    this.radius = 28,
    this.padding = EdgeInsets.zero,
    this.blur,
  });

  final Widget child;
  final VoidCallback? onTap;
  final GlassKind kind;
  final double radius;
  final EdgeInsetsGeometry padding;
  final bool? blur;

  @override
  Widget build(BuildContext context) => Glass(
    kind: kind,
    radius: radius,
    blur: blur,
    child: InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: onTap,
      child: Padding(padding: padding, child: child),
    ),
  );
}
