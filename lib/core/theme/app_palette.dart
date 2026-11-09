import 'package:flutter/material.dart';

abstract final class Metric {
  static const burn = [Color(0xFFFFB15C), Color(0xFFFF4F2E)];
  static const water = [Color(0xFF5CC8FF), Color(0xFF2F6BFF)];
  static const protein = [Color(0xFF7CF0B8), Color(0xFF14B87A)];
  static const run = [Color(0xFFC79BFF), Color(0xFF7B4DFF)];

  static const cta = [Color(0xFF4FB4FF), Color(0xFF1F5BFF)];

  static const burnDot = Color(0xFFFF5E3A);
  static const waterDot = Color(0xFF2F6BFF);
  static const proteinDot = Color(0xFF14B87A);
  static const runDot = Color(0xFF7B4DFF);
  static const alert = Color(0xFFE8343C);
  static const startDot = Color(0xFF22C38E);
}

@immutable
class Orb {
  const Orb(this.alignment, this.radius, this.color);
  final Alignment alignment;
  final double radius;
  final Color color;
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.text,
    required this.sub,
    required this.hair,
    required this.accentText,
    required this.pageTop,
    required this.pageBottom,
    required this.orbs,
    required this.glass,
    required this.glassHi,
    required this.edge,
    required this.highlight,
    required this.shadow,
    required this.bar,
    required this.tracks,
    required this.goodBg,
    required this.goodFg,
    required this.tabIdle,
    required this.mapBg,
    required this.mapRoad,
    required this.danger,
  });

  final Color text;
  final Color sub;
  final Color hair;
  final Color accentText;
  final Color pageTop;
  final Color pageBottom;
  final List<Orb> orbs;

  final List<Color> glass;

  final List<Color> glassHi;
  final Color edge;

  final Color highlight;
  final List<BoxShadow> shadow;

  final List<Color> bar;

  final List<Color> tracks;
  final Color goodBg;
  final Color goodFg;
  final Color tabIdle;
  final Color mapBg;
  final Color mapRoad;

  final Color danger;

  static const dark = AppPalette(
    text: Color(0xFFF4F5FA),
    sub: Color(0xFFA3A8B8),
    hair: Color(0x1AFFFFFF),
    accentText: Color(0xFF6FB8FF),
    pageTop: Color(0xFF0D0E18),
    pageBottom: Color(0xFF06070C),
    orbs: [
      Orb(Alignment(0.76, -0.72), 240, Color(0x763D7BFF)),
      Orb(Alignment(-1.2, -0.08), 260, Color(0x6B2F6BFF)),
      Orb(Alignment(1.0, 0.56), 240, Color(0x5D9B6BFF)),
      Orb(Alignment(-0.6, 1.04), 180, Color(0x4414B87A)),
    ],
    glass: [Color(0x24FFFFFF), Color(0x0DFFFFFF)],
    glassHi: [Color(0x29FFFFFF), Color(0x0FFFFFFF)],
    edge: Color(0x24FFFFFF),
    highlight: Color(0x29FFFFFF),
    shadow: [BoxShadow(color: Color(0x73000000), blurRadius: 40, offset: Offset(0, 20))],
    bar: [Color(0x9E1E202E), Color(0xB810111A)],
    tracks: [Color(0x2EFF6A2B), Color(0x332F6BFF), Color(0x3314B87A), Color(0x337B4DFF)],
    goodBg: Color(0x2922C38E),
    goodFg: Color(0xFF5BE3B0),
    tabIdle: Color(0xFF8E93A4),
    mapBg: Color(0xFF1E2422),
    mapRoad: Color(0xFF2E3734),
    danger: Color(0xFFFF6B72),
  );

  static const light = AppPalette(
    text: Color(0xFF0E1018),
    sub: Color(0xFF5D6273),
    hair: Color(0x140E1018),
    accentText: Color(0xFF1F55D6),
    pageTop: Color(0xFFF5F6FB),
    pageBottom: Color(0xFFE9ECF5),
    orbs: [
      Orb(Alignment(0.76, -0.72), 260, Color(0x803D9BFF)),
      Orb(Alignment(-1.2, -0.08), 280, Color(0x703D7BFF)),
      Orb(Alignment(1.0, 0.56), 260, Color(0x6A9B6BFF)),
      Orb(Alignment(-0.6, 1.04), 200, Color(0x5614B87A)),
    ],
    glass: [Color(0xC7FFFFFF), Color(0x75FFFFFF)],
    glassHi: [Color(0xDBFFFFFF), Color(0x8FFFFFFF)],
    edge: Color(0xF2FFFFFF),
    highlight: Color(0xFFFFFFFF),
    shadow: [
      BoxShadow(color: Color(0x0A161C34), blurRadius: 2, offset: Offset(0, 1)),
      BoxShadow(color: Color(0x212E386E), blurRadius: 40, offset: Offset(0, 18)),
    ],
    bar: [Color(0xCCFFFFFF), Color(0xA3FFFFFF)],
    tracks: [Color(0x29FF6A2B), Color(0x242F6BFF), Color(0x2914B87A), Color(0x297B4DFF)],
    goodBg: Color(0x2414B87A),
    goodFg: Color(0xFF0B7A52),
    tabIdle: Color(0xFF6B7080),
    mapBg: Color(0xFFE5ECE2),
    mapRoad: Color(0xFFFFFFFF),
    danger: Color(0xFFD1242C),
  );

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(covariant AppPalette? other, double t) => t < 0.5 ? this : (other ?? this);
}

extension PaletteX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
}
