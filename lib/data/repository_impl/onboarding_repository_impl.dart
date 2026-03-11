import 'package:active_tracker/data/models/hive/user_profile_model.dart';
import 'package:active_tracker/data/local/hive_manager.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:hive/hive.dart';

/// Implementation of OnboardingRepository
/// Manages user profile and onboarding state using Hive
class OnboardingRepositoryImpl implements OnboardingRepository {
  late Box<UserProfileModel> _userBox;

  OnboardingRepositoryImpl() {
    _userBox = HiveManager.getUserBox();
  }

  @override
  Future<void> getUserProfile() async {
    try {
      final profile = _userBox.get('userProfile');
      if (profile != null) {
        print('✅ User profile retrieved');
      }
    } catch (e) {
      print('❌ Error getting user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveUserProfile({
    required String userId,
    required String name,
    required int age,
    required double weight,
    required double height,
    required int goalType,
    required int intensityLevel,
  }) async {
    try {
      final now = DateTime.now();
      final profile = UserProfileModel(
        userId: userId,
        name: name,
        age: age,
        weight: weight,
        height: height,
        goalType: goalType,
        intensityLevel: intensityLevel,
        calorieGoal: 2000.0, // Default values
        proteinGoal: 150.0,
        fatGoal: 65.0,
        carbsGoal: 250.0,
        waterGoalMl: (weight * 35).toInt() + 500,
        createdAt: now,
        updatedAt: now,
      );

      await _userBox.put('userProfile', profile);
      print('✅ User profile saved');
    } catch (e) {
      print('❌ Error saving user profile: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserGoals({
    required double calorieGoal,
    required double proteinGoal,
    required double fatGoal,
    required double carbsGoal,
    required int waterGoalMl,
  }) async {
    try {
      final profile = _userBox.get('userProfile');
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updated = profile.copyWith(
        calorieGoal: calorieGoal,
        proteinGoal: proteinGoal,
        fatGoal: fatGoal,
        carbsGoal: carbsGoal,
        waterGoalMl: waterGoalMl,
        updatedAt: DateTime.now(),
      );

      await _userBox.put('userProfile', updated);
      print('✅ User goals updated');
    } catch (e) {
      print('❌ Error updating user goals: $e');
      rethrow;
    }
  }

  @override
  Future<bool> isOnboardingComplete() async {
    try {
      final profile = _userBox.get('userProfile');
      return profile != null;
    } catch (e) {
      print('❌ Error checking onboarding status: $e');
      return false;
    }
  }

  /// Get current user profile
  UserProfileModel? getUserProfileSync() {
    try {
      return _userBox.get('userProfile');
    } catch (e) {
      print('❌ Error getting user profile: $e');
      return null;
    }
  }

  /// Clear user profile (for logout)
  Future<void> clearUserProfile() async {
    try {
      await _userBox.delete('userProfile');
      print('✅ User profile cleared');
    } catch (e) {
      print('❌ Error clearing user profile: $e');
      rethrow;
    }
  }
}