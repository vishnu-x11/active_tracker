import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeSignup,
    page: () => const SignupScreen(),
    transition: Transition.rightToLeft,
  ),

  // Onboarding
  GetPage(
    name: AppConstants.routeOnboarding,
    page: () => const OnboardingScreen(),
    transition: Transition.fade,
  ),

  // Main App Screens
  GetPage(
    name: AppConstants.routeDashboard,
    page: () => const DashboardScreen(),
    transition: Transition.fade,
  ),

  GetPage(
    name: AppConstants.routeDailyLog,
    page: () => const DailyLogScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeNutrition,
    page: () => const NutritionScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeTraining,
    page: () => const TrainingScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeHydration,
    page: () => const HydrationScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeBmi,
    page: () => const BmiScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeBodyWeight,
    page: () => const BodyWeightScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeNotes,
    page: () => const NotesScreen(),
    transition: Transition.rightToLeft,
  ),

  GetPage(
    name: AppConstants.routeCalendar,
    page: () => const CalendarScreen(),
    transition: Transition.rightToLeft,
  ),
];

// ============ PLACEHOLDER SCREENS ============
// These are temporary placeholders. They'll be replaced in Phase 6.
// Each screen will be moved to: lib/presentation/screens/{module_name}/

/// Splash screen shown at app launch
class SplashScreen extends StatelessWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Active Health',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text('Initializing...'),
          ],
        ),
      ),
    );
  }
}

/// Login screen for user authentication
class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: const Center(child: Text('Login Screen - Coming in Phase 6')),
    );
  }
}

/// Sign up screen for new users
class SignupScreen extends StatelessWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: const Center(child: Text('Sign Up Screen - Coming in Phase 6')),
    );
  }
}

/// Onboarding flow for new users
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Onboarding')),
      body: const Center(child: Text('Onboarding Screen - Coming in Phase 6')),
    );
  }
}

/// Main dashboard showing daily progress
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: const Center(child: Text('Dashboard Screen - Coming in Phase 6')),
    );
  }
}

/// Daily log showing all 7 goals
class DailyLogScreen extends StatelessWidget {
  const DailyLogScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Daily Log')),
      body: const Center(child: Text('Daily Log Screen - Coming in Phase 6')),
    );
  }
}

/// Nutrition tracking screen
class NutritionScreen extends StatelessWidget {
  const NutritionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nutrition')),
      body: const Center(child: Text('Nutrition Screen - Coming in Phase 6')),
    );
  }
}

/// Training/workout screen
class TrainingScreen extends StatelessWidget {
  const TrainingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training')),
      body: const Center(child: Text('Training Screen - Coming in Phase 6')),
    );
  }
}

/// Water hydration tracking screen
class HydrationScreen extends StatelessWidget {
  const HydrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hydration')),
      body: const Center(child: Text('Hydration Screen - Coming in Phase 6')),
    );
  }
}

/// BMI calculator and tracking screen
class BmiScreen extends StatelessWidget {
  const BmiScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('BMI Calculator')),
      body: const Center(child: Text('BMI Screen - Coming in Phase 6')),
    );
  }
}

/// Body weight tracking screen (push-ups, pull-ups)
class BodyWeightScreen extends StatelessWidget {
  const BodyWeightScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Body Weight')),
      body: const Center(child: Text('Body Weight Screen - Coming in Phase 6')),
    );
  }
}

/// Notes/journal screen
class NotesScreen extends StatelessWidget {
  const NotesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notes')),
      body: const Center(child: Text('Notes Screen - Coming in Phase 6')),
    );
  }
}

/// Calendar view of daily logs
class CalendarScreen extends StatelessWidget {
  const CalendarScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendar')),
      body: const Center(child: Text('Calendar Screen - Coming in Phase 6')),
    );
  }
}