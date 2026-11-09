import 'package:flutter/material.dart';

import 'app_palette.dart';

abstract final class AppText {
  static const _tnum = [FontFeature.tabularFigures()];

  static const hero = TextStyle(
    fontSize: 52,
    fontWeight: FontWeight.w700,
    letterSpacing: -2.4,
    height: 1,
    fontFeatures: _tnum,
  );
  static const display = TextStyle(fontSize: 30, fontWeight: FontWeight.w700, letterSpacing: -0.6);
  static const title = TextStyle(fontSize: 17, fontWeight: FontWeight.w600);
  static const section = TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3);
  static const cardTitle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static const number = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.4, fontFeatures: _tnum);
  static const body = TextStyle(fontSize: 14, fontWeight: FontWeight.w500);
  static const small = TextStyle(fontSize: 13, fontWeight: FontWeight.w400);
  static const eyebrow = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8);
  static const tab = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
}

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppPalette.light);
  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final base = ThemeData(
      brightness: brightness,
      fontFamily: 'Inter',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Metric.cta.last, brightness: brightness, surface: p.pageBottom),
      scaffoldBackgroundColor: Colors.transparent,
      splashFactory: InkSparkle.splashFactory,
    );
    return base.copyWith(
      textTheme: base.textTheme.apply(fontFamily: 'Inter', bodyColor: p.text, displayColor: p.text),
      extensions: [p],
    );
  }
}
