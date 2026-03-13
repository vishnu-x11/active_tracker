import 'package:active_tracker/data/repository_impl/bmi_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/daily_log_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/hydration_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/nutrition_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/onboarding_repository_impl.dart';
import 'package:active_tracker/data/repository_impl/training_repository_impl.dart';
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

    print('✅ AppBinding: Global dependencies ready');
  }
}

// ============ AUTH BINDING ============
/// Authentication binding
class AuthBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 AuthBinding: Setting up authentication...');

    Get.lazyPut<AuthController>(
          () => AuthController(),
    );

    print('✅ AuthBinding: Authentication ready');
  }
}

// ============ ONBOARDING BINDING ============
/// Onboarding module binding
class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 OnboardingBinding: Setting up onboarding...');

    Get.lazyPut<OnboardingRepository>(
          () => OnboardingRepositoryImpl(),
      tag: 'onboarding',
    );

    Get.lazyPut<OnboardingController>(
          () => OnboardingController(
        Get.find<OnboardingRepository>(tag: 'onboarding'),
      ),
      tag: 'onboarding',
    );

    print('✅ OnboardingBinding: Onboarding ready');
  }
}

// ============ DASHBOARD BINDING ============
/// Dashboard module binding
class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    print('🔧 DashboardBinding: Setting up dashboard...');

    Get.lazyPut<DashboardController>(
          () => DashboardController(),
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
          () => NutritionRepositoryImpl(userId: 'current-user-id'),
      tag: 'nutrition',
    );

    Get.lazyPut<NutritionController>(
          () => NutritionController(
        Get.find<NutritionRepository>(tag: 'nutrition'),
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
          () => TrainingRepositoryImpl(userId: 'current-user-id'),
      tag: 'training',
    );

    Get.lazyPut<TrainingController>(
          () => TrainingController(
        Get.find<TrainingRepository>(tag: 'training'),
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
          () => HydrationRepositoryImpl(userId: 'current-user-id'),
      tag: 'hydration',
    );

    Get.lazyPut<HydrationController>(
          () => HydrationController(
        Get.find<HydrationRepository>(tag: 'hydration'),
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
          () => BmiRepositoryImpl(userId: 'current-user-id'),
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
          () => DailyLogRepositoryImpl(userId: 'current-user-id'),
      tag: 'daily_log',
    );

    Get.lazyPut<DailyLogController>(
          () => DailyLogController(
        Get.find<DailyLogRepository>(tag: 'daily_log'),
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