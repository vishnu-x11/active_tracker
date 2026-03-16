import 'package:active_tracker/presentation/pages/bmi_screen.dart';
import 'package:active_tracker/presentation/pages/body_weight_screen.dart';
import 'package:active_tracker/presentation/pages/calendar_screen.dart';
import 'package:active_tracker/presentation/pages/daily_log_screen.dart';
import 'package:active_tracker/presentation/pages/dashboard_screen.dart';
import 'package:active_tracker/presentation/pages/hydration_screen.dart';
import 'package:active_tracker/presentation/pages/login_screen.dart';
import 'package:active_tracker/presentation/pages/notes_screen.dart';
import 'package:active_tracker/presentation/pages/nutrition_screen.dart';
import 'package:active_tracker/presentation/pages/onboarding_screen.dart';
import 'package:active_tracker/presentation/pages/settings_screen.dart';
import 'package:active_tracker/presentation/pages/signup_screen.dart';
import 'package:active_tracker/presentation/pages/splash_screen.dart';
import 'package:active_tracker/presentation/pages/training_screen.dart';
import 'package:active_tracker/presentation/pages/analytics_screen.dart';
import 'package:active_tracker/presentation/pages/workout_programs_screen.dart';
import 'package:active_tracker/presentation/pages/meal_planning_screen.dart';
import 'package:active_tracker/presentation/pages/goals_screen.dart';
import 'package:active_tracker/presentation/pages/achievements_screen.dart';
import 'package:active_tracker/presentation/pages/social_screen.dart';
import 'package:active_tracker/presentation/pages/body_metrics_screen.dart';
import 'package:active_tracker/presentation/pages/devices_screen.dart';
import 'package:active_tracker/presentation/pages/ai_coach_screen.dart';
import 'package:active_tracker/presentation/pages/pricing_screen.dart';
import 'package:active_tracker/presentation/screens/auth/otp_screen.dart';
import 'package:get/get.dart';
import 'package:active_tracker/presentation/bindings/app_binding.dart';
import 'constants.dart';


// ============ ROUTE NAMES ============
class AppRoutes {
  static const String splash = AppConstants.routeSplash;
  static const String login = AppConstants.routeLogin;
  static const String signup = AppConstants.routeSignup;
  static const String onboarding = AppConstants.routeOnboarding;
  static const String dashboard = AppConstants.routeDashboard;
  static const String dailyLog = AppConstants.routeDailyLog;
  static const String nutrition = AppConstants.routeNutrition;
  static const String training = AppConstants.routeTraining;
  static const String hydration = AppConstants.routeHydration;
  static const String bmi = AppConstants.routeBmi;
  static const String bodyWeight = AppConstants.routeBodyWeight;
  static const String notes = AppConstants.routeNotes;
  static const String calendar = AppConstants.routeCalendar;
}

// ============ GET PAGES ============
final List<GetPage<dynamic>> appPages = [
  // Splash Screen
  GetPage(
    name: AppConstants.routeSplash,
    page: () => const SplashScreen(),
    transition: Transition.fade,
  ),

  // Auth Screens
  GetPage(
    name: AppConstants.routeLogin,
    page: () => const LoginScreen(),
    binding: AuthBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeSignup,
    page: () => const SignupScreen(),
    binding: AuthBinding(),
    transition: Transition.rightToLeft,
  ),

  // Onboarding
  GetPage(
    name: AppConstants.routeOnboarding,
    page: () => const OnboardingScreen(),
    binding: OnboardingBinding(),
    transition: Transition.fade,
  ),

  // Main App Screens
  GetPage(
    name: AppConstants.routeDashboard,
    page: () => const DashboardScreen(),
    binding: DashboardBinding(),
    transition: Transition.fade,
  ),

  GetPage(
    name: AppConstants.routeDailyLog,
    page: () => const DailyLogScreen(),
    binding: DailyLogBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeNutrition,
    page: () => const NutritionScreen(),
    binding: NutritionBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeTraining,
    page: () => const TrainingScreen(),
    binding: TrainingBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeHydration,
    page: () => const HydrationScreen(),
    binding: HydrationBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeBmi,
    page: () => const BmiScreen(),
    binding: BmiBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeBodyWeight,
    page: () => const BodyWeightScreen(),
    binding: BmiBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeNotes,
    page: () => const NotesScreen(),
    binding: DailyLogBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeCalendar,
    page: () => const CalendarScreen(),
    binding: DailyLogBinding(),
    transition: Transition.rightToLeft,
  ),
  
  GetPage(
    name: AppConstants.routeSettings,
    page: () => const SettingsScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeOtp,
    page: () => const OtpScreen(),
    binding: AuthBinding(),
    transition: Transition.fadeIn,
  ),

  GetPage(
    name: AppConstants.routeAnalytics,
    page: () => const AnalyticsScreen(),
    binding: AnalyticsBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeWorkoutPrograms,
    page: () => const WorkoutProgramsScreen(),
    binding: WorkoutBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeMealPlanning,
    page: () => const MealPlanningScreen(),
    binding: MealPlanningBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeGoals,
    page: () => const GoalsScreen(),
    binding: GoalsBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeAchievements,
    page: () => const AchievementsScreen(),
    binding: GamificationBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeSocial,
    page: () => const SocialScreen(),
    binding: SocialBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeBodyMetrics,
    page: () => const BodyMetricsScreen(),
    binding: BodyMetricsBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeDevices,
    page: () => const DevicesScreen(),
    binding: DeviceBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeAICoach,
    page: () => AICoachScreen(),
    binding: AICoachBinding(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routePricing,
    page: () => const PricingScreen(),
    binding: PremiumBinding(),
    transition: Transition.rightToLeft,
  ),
];
