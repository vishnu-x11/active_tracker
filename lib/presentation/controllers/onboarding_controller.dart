import 'package:get/get.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/presentation/controllers/auth_controller.dart';

/// Manages user onboarding flow and profile setup
class OnboardingController extends GetxController {
  // ============ DEPENDENCIES ============
  final OnboardingRepository _repository;

  // ============ OBSERVABLE STATE ============
  final currentStep = 0.obs;
  final userName = ''.obs;
  final userAge = 0.obs;
  final userWeight = 0.0.obs;
  final userHeight = 0.0.obs;
  final goalType = 1.obs;
  final intensityLevel = 1.obs;
  final burnedCalorieGoal = 500.0.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final isOnboardingComplete = false.obs;

  // ============ CONSTRUCTOR ============
  OnboardingController(this._repository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ OnboardingController initialized');
    checkOnboardingStatus();
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ OnboardingController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ OnboardingController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Check if user has completed onboarding
  Future<void> checkOnboardingStatus() async {
    try {
      isLoading.value = true;
      final complete = await _repository.isOnboardingComplete();
      isOnboardingComplete.value = complete;
      print('✅ Onboarding status checked');
    } catch (e) {
      errorMessage.value = 'Failed to check onboarding: $e';
      print('❌ Error checking onboarding status: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Move to next onboarding step
  void nextStep() {
    if (validateCurrentStep()) {
      if (currentStep.value < 5) {
        currentStep.value++;
        print('📍 Moved to step ${currentStep.value}');
      }
    } else {
      Get.snackbar(
        'Required',
        'Please complete this step to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  /// Move to previous onboarding step
  void previousStep() {
    if (currentStep.value > 0) {
      currentStep.value--;
      print('📍 Moved to step ${currentStep.value}');
    }
  }

  /// Complete onboarding and save user profile
  Future<void> completeOnboarding() async {
    if (!validateCurrentStep()) {
      Get.snackbar(
        'Required',
        'Please complete this step to continue',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _repository.saveUserProfile(
        userId: Get.find<AuthController>().userId.value,
        name: userName.value,
        age: userAge.value,
        weight: userWeight.value,
        height: userHeight.value,
        goalType: goalType.value,
        intensityLevel: intensityLevel.value,
        burnedCalorieGoal: burnedCalorieGoal.value,
      );

      isOnboardingComplete.value = true;
      print('✅ Onboarding completed successfully');
      Get.offAllNamed('/dashboard');
    } catch (e) {
      errorMessage.value = 'Failed to complete onboarding: $e';
      print('❌ Onboarding error: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  // ============ HELPER METHODS ============

  /// Validate current step
  bool validateCurrentStep() {
    switch (currentStep.value) {
      case 0: // Name
        return userName.value.isNotEmpty;
      case 1: // Age
        return userAge.value > 0;
      case 2: // Weight
        return userWeight.value > 0;
      case 3: // Height
        return userHeight.value > 0;
      case 4: // Goal
        return goalType.value > 0;
      case 5: // Burned Calories Goal
        return burnedCalorieGoal.value > 0;
      default:
        return false;
    }
  }

  /// Get step progress (0.0 to 1.0)
  double getProgress() => (currentStep.value + 1) / 6.0;

  /// Get step title
  String getStepTitle() {
    switch (currentStep.value) {
      case 0:
        return 'What\'s your name?';
      case 1:
        return 'How old are you?';
      case 2:
        return 'Your measurements';
      case 4:
        return 'What\'s your goal?';
      case 5:
        return 'Workout goal';
      default:
        return '';
    }
  }

  /// Is at last step
  bool get isLastStep => currentStep.value == 5;

  /// Can proceed to next step
  bool get canProceed => validateCurrentStep();
}