import 'package:hive_flutter/hive_flutter.dart';
import '../../config/constants.dart';
import '../models/hive/user_profile_model.dart';
import '../models/hive/water_log_model.dart';
import '../models/hive/bmi_result_model.dart';
import '../models/hive/note_model.dart';

class HiveManager {
  static Future<void> init() async {
    try {
      // ============ STEP 1: Initialize Hive with Flutter ============
      await Hive.initFlutter();

      // ============ STEP 2: Register Hive Adapters ============
      // CRITICAL: typeIds must match model definitions (0, 2, 3, 4)
      Hive.registerAdapter(UserProfileModelAdapter());
      Hive.registerAdapter(WaterLogModelAdapter());
      Hive.registerAdapter(BmiResultModelAdapter());
      Hive.registerAdapter(NoteModelAdapter());

      // ============ STEP 3: Open Hive Boxes ============
      await Hive.openBox<UserProfileModel>(AppConstants.userBoxName);
      await Hive.openBox<WaterLogModel>(AppConstants.waterLogBoxName);
      await Hive.openBox<BmiResultModel>(AppConstants.bmiResultBoxName);
      await Hive.openBox<NoteModel>(AppConstants.noteBoxName);
      await Hive.openBox(AppConstants.authBoxName);
      await Hive.openBox(AppConstants.appSettingsBoxName);
      await Hive.openBox(AppConstants.premiumSettingsBoxName);

      print('✅ Hive initialized successfully');
    } catch (e) {
      print('❌ Hive initialization failed: $e');
      rethrow;
    }
  }

  /// Get user profile box
  static Box<UserProfileModel> getUserBox() {
    return Hive.box<UserProfileModel>(AppConstants.userBoxName);
  }

  /// Get water log box
  static Box<WaterLogModel> getWaterLogBox() {
    return Hive.box<WaterLogModel>(AppConstants.waterLogBoxName);
  }

  /// Get BMI result box
  static Box<BmiResultModel> getBmiResultBox() {
    return Hive.box<BmiResultModel>(AppConstants.bmiResultBoxName);
  }

  /// Get notes box
  static Box<NoteModel> getNotesBox() {
    return Hive.box<NoteModel>(AppConstants.noteBoxName);
  }

  /// Get auth box
  static Box getAuthBox() {
    return Hive.box(AppConstants.authBoxName);
  }

  /// Get app settings box
  static Box getAppSettingsBox() {
    return Hive.box(AppConstants.appSettingsBoxName);
  }

  /// Get premium settings box
  static Box getPremiumSettingsBox() {
    return Hive.box(AppConstants.premiumSettingsBoxName);
  }
}