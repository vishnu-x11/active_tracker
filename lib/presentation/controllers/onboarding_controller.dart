import 'package:get/get.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';

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
    if (currentStep.value < 4) {
      currentStep.value++;
      print('📍 Moved to step ${currentStep.value}');
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
    try {
      isLoading.value = true;
      errorMessage.value = '';

      await _repository.saveUserProfile(
        userId: 'current-user-id',
        name: userName.value,
        age: userAge.value,
        weight: userWeight.value,
        height: userHeight.value,
        goalType: goalType.value,
        intensityLevel: intensityLevel.value,
      );

      isOnboardingComplete.value = true;
      print('✅ Onboarding completed successfully');
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
      case 2: // Weight & Height
        return userWeight.value > 0 && userHeight.value > 0;
      case 3: // Goal
        return goalType.value > 0;
      case 4: // Intensity
        return intensityLevel.value > 0;
      default:
        return false;
    }
  }

  /// Get step progress (0.0 to 1.0)
  double getProgress() => (currentStep.value + 1) / 5.0;

  /// Get step title
  String getStepTitle() {
    switch (currentStep.value) {
      case 0:
        return 'What\'s your name?';
      case 1:
        return 'How old are you?';
      case 2:
        return 'Your measurements';
      case 3:
        return 'What\'s your goal?';
      case 4:
        return 'Activity level';
      default:
        return '';
    }
  }

  /// Is at last step
  bool get isLastStep => currentStep.value == 4;

  /// Can proceed to next step
  bool get canProceed => validateCurrentStep();
}