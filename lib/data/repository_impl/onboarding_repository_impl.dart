import 'package:active_tracker/data/models/hive/user_profile_model.dart';
import 'package:active_tracker/data/local/hive_manager.dart';
import 'package:active_tracker/data/sync/sync_manager.dart';
import 'package:active_tracker/data/sync/firebase_sync.dart';
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
    required double burnedCalorieGoal,
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
        burnedCalorieGoal: burnedCalorieGoal,
        waterGoalMl: (weight * 35).toInt() + 500,
        createdAt: now,
        updatedAt: now,
      );

      await _userBox.put('userProfile', profile);

      // Queue for sync
      await SyncManager().queueOperation(
        userId: userId,
        operationType: 'update',
        tableName: 'user_profiles',
        entityId: userId,
        data: profile.toMap(),
      );

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

      // Queue for sync
      await SyncManager().queueOperation(
        userId: updated.userId,
        operationType: 'update',
        tableName: 'user_profiles',
        entityId: updated.userId,
        data: updated.toMap(),
      );

      print('✅ User goals updated');
    } catch (e) {
      print('❌ Error updating user goals: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateUserProfileImage(String imageUrl) async {
    try {
      final profile = _userBox.get('userProfile');
      if (profile == null) {
        throw Exception('User profile not found');
      }

      final updated = profile.copyWith(
        imageUrl: imageUrl,
        updatedAt: DateTime.now(),
      );

      await _userBox.put('userProfile', updated);

      // Queue for sync
      await SyncManager().queueOperation(
        userId: updated.userId,
        operationType: 'update',
        tableName: 'user_profiles',
        entityId: updated.userId,
        data: updated.toMap(),
      );

      print('✅ User profile image updated');
    } catch (e) {
      print('❌ Error updating profile image: $e');
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

  @override
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

  @override
  Future<bool> syncUserProfileFromCloud(String userId) async {
    try {
      final cloudProfile = await FirebaseSync().pullUserProfile(userId);
      if (cloudProfile != null) {
        await _userBox.put('userProfile', cloudProfile);
        print('✅ User profile synced from cloud for: $userId');
        return true;
      }
      return false;
    } catch (e) {
      print('❌ Error syncing profile from cloud: $e');
      return false;
    }
  }
}