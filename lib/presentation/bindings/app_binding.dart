import 'package:active_tracker/data/sync/sync_nutrition_repository.dart';
import 'package:active_tracker/data/sync/sync_training_repository.dart';
import 'package:active_tracker/data/sync/sync_hydration_repository.dart';
import 'package:active_tracker/data/sync/sync_bmi_repository.dart';
import 'package:active_tracker/data/repository_impl/onboarding_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/nutrition_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/training_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/hydration_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/bmi_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/daily_log_repository_impl.dart';
import 'package:active_tracker/presentation/controllers/analytics/analytics_controller.dart';
import 'package:active_tracker/presentation/controllers/workouts/workout_programs_controller.dart';
import 'package:active_tracker/presentation/controllers/nutrition/meal_planning/meal_planning_controller.dart';
import 'package:active_tracker/presentation/controllers/goals/goals_controller.dart';
import 'package:active_tracker/presentation/controllers/gamification/gamification_controller.dart';
import 'package:active_tracker/presentation/controllers/social/social_controller.dart';
import 'package:active_tracker/presentation/controllers/body_metrics/body_metrics_controller.dart';
import 'package:active_tracker/presentation/controllers/devices/device_controller.dart';
import 'package:active_tracker/presentation/controllers/ai_coach/ai_coach_controller.dart';
import 'package:active_tracker/presentation/controllers/premium/premium_controller.dart';
import 'package:get/get.dart';

import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/data/sync/connectivity_monitor.dart';
import 'package:active_tracker/data/sync/offline_queue_manager.dart';
import 'package:active_tracker/data/sync/firebase_sync.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';
import 'package:active_tracker/presentation/controllers/onboarding_controller.dart';
import 'package:active_tracker/presentation/controllers/sync_status_controller.dart';
import 'package:active_tracker/presentation/controllers/dashboard_controller.dart';
import 'package:active_tracker/presentation/controllers/nutrition_controller.dart';
import 'package:active_tracker/presentation/controllers/training_controller.dart';
import 'package:active_tracker/presentation/controllers/hydration_controller.dart';
import 'package:active_tracker/presentation/controllers/bmi_controller.dart';
import 'package:active_tracker/presentation/controllers/daily_log_controller.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';

// ============ APP BINDING ============
/// Global app dependencies binding
class AppBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 AppBinding: Setting up global dependencies...');

    // Sync infrastructure (permanent singletons)
    Get.put<ConnectivityMonitor>(
      ConnectivityMonitor(),
      permanent: true,
    );

    Get.put<SyncManager>(
      SyncManager(),
      permanent: true,
    );

    Get.put<OfflineQueueManager>(
      OfflineQueueManager(),
      permanent: true,
    );

    Get.put<FirebaseSync>(
      FirebaseSync(),
      permanent: true,
    );

    // Sync status controller (permanent)
    Get.put<SyncStatusController>(
      SyncStatusController(
        Get.find<SyncManager>(),
        Get.find<ConnectivityMonitor>(),
        Get.find<OfflineQueueManager>(),
      ),
      permanent: true,
    );

    // ============ CORE REPOSITORIES ============
    // These must be registered BEFORE controllers that depend on them
    
    Get.put<OnboardingRepository>(
      OnboardingRepositoryImpl(),
      permanent: true,
    );

    Get.put<HydrationRepository>(
      HydrationRepositoryImpl(),
      permanent: true,
    );

    Get.put<DailyLogRepository>(
      DailyLogRepositoryImpl(
        hydrationRepository: Get.find<HydrationRepository>(),
      ),
      permanent: true,
    );

    // Authentication (permanent global)
    Get.put<AuthController>(
      AuthController(),
      permanent: true,
    );

    // ============ PREMIUM INFRASTRUCTURE (New in v4.0) ============
    Get.put<PremiumController>(
      PremiumController(),
      permanent: true,
    );

    print('✅ AppBinding: Global dependencies ready');
  }
}

// ============ AUTH BINDING ============
/// Authentication binding
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 AuthBinding: Already configured globally in AppBinding');
    print('✅ AuthBinding: Ready');
  }
}

// ============ ONBOARDING BINDING ============
/// Onboarding module binding
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 OnboardingBinding: Dependencies already handled in AppBinding');
    
    // Ensure controller is available if not already
    try {
      Get.find<OnboardingController>(tag: 'onboarding');
    } catch (_) {
      Get.put<OnboardingController>(
        OnboardingController(
          Get.find<OnboardingRepository>(),
        ),
        tag: 'onboarding',
        permanent: true,
      );
    }
    
    print('✅ OnboardingBinding: Ready');
  }
}

// ============ DASHBOARD BINDING ============
/// Dashboard module binding
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 DashboardBinding: Setting up dashboard...');

    Get.lazyPut<DashboardController>(
          () => DashboardController(
            Get.find<DailyLogRepository>(),
            Get.find<OnboardingRepository>(),
          ),
      tag: 'dashboard',
    );

    print('✅ DashboardBinding: Dashboard ready');
  }
}

// ============ NUTRITION BINDING ============
/// Nutrition module binding
class NutritionBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 NutritionBinding: Setting up nutrition...');

    Get.lazyPut<NutritionRepository>(
          () => SyncNutritionRepository(
            userId: Get.find<AuthController>().userId.value,
            localRepository: NutritionRepositoryImpl(),
          ),
      tag: 'nutrition',
    );

    Get.lazyPut<NutritionController>(
          () => NutritionController(
        Get.find<NutritionRepository>(tag: 'nutrition'),
        Get.find<DailyLogRepository>(),
      ),
      tag: 'nutrition',
    );

    print('✅ NutritionBinding: Nutrition ready');
  }
}

// ============ TRAINING BINDING ============
/// Training module binding
class TrainingBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 TrainingBinding: Setting up training...');

    Get.lazyPut<TrainingRepository>(
          () => SyncTrainingRepository(
            userId: Get.find<AuthController>().userId.value,
            localRepository: TrainingRepositoryImpl(),
          ),
      tag: 'training',
    );

    Get.lazyPut<TrainingController>(
          () => TrainingController(
        Get.find<TrainingRepository>(tag: 'training'),
        Get.find<DailyLogRepository>(),
      ),
      tag: 'training',
    );

    print('✅ TrainingBinding: Training ready');
  }
}

// ============ HYDRATION BINDING ============
/// Hydration module binding
class HydrationBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 HydrationBinding: Setting up hydration...');

    Get.lazyPut<HydrationRepository>(
          () => SyncHydrationRepository(
            userId: Get.find<AuthController>().userId.value,
            localRepository: HydrationRepositoryImpl(),
          ),
      tag: 'hydration',
    );

    Get.lazyPut<HydrationController>(
          () => HydrationController(
        Get.find<HydrationRepository>(),
        Get.find<DailyLogRepository>(),
      ),
      tag: 'hydration',
    );

    print('✅ HydrationBinding: Hydration ready');
  }
}

// ============ BMI BINDING ============
/// BMI module binding
class BmiBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 BmiBinding: Setting up BMI...');

    Get.lazyPut<BmiRepository>(
          () => SyncBmiRepository(
            userId: Get.find<AuthController>().userId.value,
            localRepository: BmiRepositoryImpl(),
          ),
      tag: 'bmi',
    );

    Get.lazyPut<BmiController>(
          () => BmiController(
        Get.find<BmiRepository>(tag: 'bmi'),
      ),
      tag: 'bmi',
    );

    print('✅ BmiBinding: BMI ready');
  }
}

// ============ DAILY LOG BINDING ============
/// Daily log module binding
class DailyLogBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 DailyLogBinding: Setting up daily log...');

    Get.lazyPut<DailyLogRepository>(
          () => DailyLogRepositoryImpl(
            hydrationRepository: Get.find<HydrationRepository>(),
          ),
      tag: 'daily_log',
    );

    Get.lazyPut<DailyLogController>(
          () => DailyLogController(
        Get.find<DailyLogRepository>(),
      ),
      tag: 'daily_log',
    );

    print('✅ DailyLogBinding: Daily log ready');
  }
}

// ============ SYNC BINDING ============
/// Sync status binding (if used separately from AppBinding)
class SyncBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 SyncBinding: Sync dependencies...');

    // Already created in AppBinding, just ensure availability
    Get.find<SyncStatusController>();

    print('✅ SyncBinding: Sync ready');
  }
}

// ============ ANALYTICS BINDING (New in v4.0) ============
class AnalyticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AnalyticsController>(() => AnalyticsController());
  }
}

// ============ WORKOUT BINDING (New in v4.0) ============
class WorkoutBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<WorkoutProgramsController>(() => WorkoutProgramsController());
  }
}

// ============ MEAL PLANNING BINDING (New in v4.0) ============
class MealPlanningBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<MealPlanningController>(() => MealPlanningController());
  }
}

// ============ GOALS BINDING (New in v4.0) ============
class GoalsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoalsController>(() => GoalsController());
  }
}

// ============ GAMIFICATION BINDING (New in v4.0) ============
class GamificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GamificationController>(() => GamificationController());
  }
}

// ============ SOCIAL BINDING (New in v4.0) ============
class SocialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SocialController>(() => SocialController());
  }
}

// ============ BODY METRICS BINDING (New in v4.0) ============
class BodyMetricsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<BodyMetricsController>(() => BodyMetricsController());
  }
}

// ============ DEVICE BINDING (New in v4.0) ============
class DeviceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DeviceController>(() => DeviceController());
  }
}

// ============ AI COACH BINDING (New in v4.0) ============
class AICoachBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AICoachController>(() => AICoachController());
  }
}

// ============ PREMIUM BINDING (New in v4.0) ============
class PremiumBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PremiumController>(() => PremiumController());
  }
}