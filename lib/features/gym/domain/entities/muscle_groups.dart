abstract final class MuscleGroups {
  static const builtIn = <String, String>{
    'chest': 'Chest',
    'back': 'Back',
    'shoulders': 'Shoulders',
    'biceps': 'Biceps',
    'triceps': 'Triceps',
    'legs': 'Legs',
    'core': 'Core',
    'full_body': 'Full body',
    'cardio': 'Cardio',
  };

  static String label(String key) => builtIn[key] ?? key;

  static String title(List<String> keys) {
    final names = keys.map(label).toList();
    if (names.length <= 2) return names.join(' + ');
    return '${names.take(2).join(' + ')} + ${names.length - 2} more';
  }

  static const maxCustomLength = 24;
}
