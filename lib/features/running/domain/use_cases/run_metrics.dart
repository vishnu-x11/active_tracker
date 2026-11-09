import '../../../../core/formulas/formulas.dart';

abstract final class RunMetrics {
  static const maxKm = 400.0;

  static double? km(String text) {
    final v = double.tryParse(text.trim().replaceAll(',', '.'));
    return v != null && v > 0 && v < maxKm ? v : null;
  }

  static int? seconds(String text) {
    final d = parseClock(text);
    return d != null && d.inSeconds > 0 ? d.inSeconds : null;
  }

  static String clock(int seconds) {
    final h = seconds ~/ 3600, m = (seconds % 3600) ~/ 60, s = seconds % 60;
    final mmss = '${h > 0 ? m.toString().padLeft(2, '0') : m}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$mmss' : mmss;
  }

  static String? paceFor(String kmText, String timeText) {
    final k = km(kmText), s = seconds(timeText);
    return k == null || s == null ? null : formatPace(s / k);
  }

  static String? timeForPace(String kmText, String paceText) {
    final k = km(kmText), p = seconds(paceText);
    return k == null || p == null ? null : clock((p * k).round());
  }
}
