abstract final class BodyStatsRules {
  static const minWeightKg = 30.0, maxWeightKg = 250.0;
  static const minHeightCm = 120.0, maxHeightCm = 230.0;
  static const minAge = 13, maxAge = 100;

  static double? parseDecimal(String text) => double.tryParse(text.trim().replaceAll(',', '.'));
  static int? parseWhole(String text) => int.tryParse(text.trim());

  static String? weight(String text) {
    if (text.trim().isEmpty) return 'Enter your weight';
    final v = parseDecimal(text);
    if (v == null || v < minWeightKg || v > maxWeightKg) return 'Weight must be 30 to 250 kg';
    return null;
  }

  static String? height(String text) {
    if (text.trim().isEmpty) return 'Enter your height';
    final v = parseDecimal(text);
    if (v == null || v < minHeightCm || v > maxHeightCm) return 'Height must be 120 to 230 cm';
    return null;
  }

  static String? age(String text) {
    if (text.trim().isEmpty) return null;
    final v = parseWhole(text);
    if (v == null || v < minAge || v > maxAge) return 'Age must be 13 to 100';
    return null;
  }

  static String? burnTarget(String text) {
    if (text.trim().isEmpty) return 'Enter a daily burn target';
    final v = parseWhole(text);
    if (v == null || v <= 0) return 'Use a whole number above 0';
    return null;
  }

  static const minProteinRatio = 0.8, maxProteinRatio = 3.0;
  static const minWaterPerKg = 20, maxWaterPerKg = 60;

  static String? proteinRatio(String text) {
    final v = parseDecimal(text);
    if (v == null || v < minProteinRatio || v > maxProteinRatio) return 'Use 0.8 to 3.0 g per kg';
    return null;
  }

  static String? waterPerKg(String text) {
    final v = parseWhole(text);
    if (v == null || v < minWaterPerKg || v > maxWaterPerKg) return 'Use 20 to 60 ml per kg';
    return null;
  }
}
