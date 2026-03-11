class AppConstants {
  // ============ APP INFO ============
  static const String appName = 'Active Health';
  static const String appVersion = '3.2.0';

  // ============ HIVE BOX NAMES ============
  static const String userBoxName = 'userBox';
  static const String waterLogBoxName = 'waterLogBox';
  static const String bmiResultBoxName = 'bmiResultBox';
  static const String noteBoxName = 'noteBox';

  // ============ WATER CALCULATION ============
  static const double waterMlPerKg = 35.0;
  static const double waterWorkoutBonus = 500.0; // ml on workout days

  // ============ DEFAULT GOALS ============
  static const int defaultPushupGoal = 50;
  static const int defaultPullupGoal = 20;
  static const double defaultCalorieGoal = 2000.0;
  static const double defaultProteinGoal = 150.0;
  static const double defaultFatGoal = 65.0;
  static const double defaultCarbsGoal = 250.0;

  // ============ GOAL MET THRESHOLDS ============
  static const double caloriesThreshold = 0.90; // 90% of target
  static const double proteinThreshold = 0.90; // 90% of target
  static const double fatMinThreshold = 0.80; // 80% of target
  static const double fatMaxThreshold = 1.20; // 120% of target
  static const double carbsThreshold = 0.85; // 85% of target
  static const double waterThreshold = 1.00; // 100% of target

  // ============ BMI GOAL TYPES ============
  static const int goalWeightLoss = 1;
  static const int goalModerateWeightLoss = 2;
  static const int goalMaintenance = 3;
  static const int goalMuscleGain = 4;
  static const int goalIntenseMuscleGain = 5;
  static const int goalCustom = 6;

  // ============ BMI INTENSITIES ============
  static const int intensityLow = 1;
  static const int intensityModerate = 2;
  static const int intensityHigh = 3;
  static const int intensityVeryHigh = 4;
  static const int intensityExtreme = 5;

  // ============ BODY PARTS ============
  static const List<String> bodyParts = [
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  // ============ MOODS ============
  static const List<String> moods = ['happy', 'neutral', 'sad'];

  // ============ EXERCISE TYPES ============
  static const String exerciseTypePushup = 'pushup';
  static const String exerciseTypePullup = 'pullup';

  // ============ DATABASE NAMES ============
  static const String sqliteDbName = 'active_health.db';
  static const String firebaseProjectId = 'active-health';

  // ============ DAILY GOALS ============
  static const List<String> dailyGoals = [
    'Calories',
    'Protein',
    'Fat',
    'Carbs',
    'Water',
    'Workout',
    'Notes',
  ];

  // ============ ROUTE NAMES ============
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeSignup = '/signup';
  static const String routeOnboarding = '/onboarding';
  static const String routeDashboard = '/dashboard';
  static const String routeDailyLog = '/daily-log';
  static const String routeNutrition = '/nutrition';
  static const String routeTraining = '/training';
  static const String routeHydration = '/hydration';
  static const String routeBmi = '/bmi';
  static const String routeBodyWeight = '/body-weight';
  static const String routeNotes = '/notes';
  static const String routeCalendar = '/calendar';
}

class HiveTypeIds {
  // Central registry of Hive typeIds - NEVER REUSE
  static const int userProfile = 0;
  static const int waterLog = 2;
  static const int bmiResult = 3;
  static const int note = 4;
// 5+ RESERVED for future use
}

class AppPadding {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
}

class AppRadius {
  static const double sm = 4.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double circle = 50.0;
}

class AppFontSize {
  static const double xs = 10.0;
  static const double sm = 12.0;
  static const double base = 14.0;
  static const double lg = 16.0;
  static const double xl = 18.0;
  static const double xxl = 20.0;
  static const double h6 = 20.0;
  static const double h5 = 24.0;
  static const double h4 = 28.0;
  static const double h3 = 32.0;
  static const double h2 = 36.0;
  static const double h1 = 40.0;
}