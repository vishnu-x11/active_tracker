import 'package:active_health/config/constants.dart';
import 'package:active_health/data/models/hive/bmi_result_model.dart';
import 'package:active_health/data/models/hive/note_model.dart';
import 'package:active_health/data/models/hive/user_profile_model.dart';
import 'package:active_health/data/models/hive/water_log_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';


class HiveManager {
  static late Box<UserProfileModel> _userBox;
  static late Box<WaterLogModel> _waterLogBox;
  static late Box<BmiResultModel> _bmiResultBox;
  static late Box<NoteModel> _noteBox;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      Hive.registerAdapter(UserProfileModelAdapter());
      Hive.registerAdapter(WaterLogModelAdapter());
      Hive.registerAdapter(BmiResultModelAdapter());
      Hive.registerAdapter(NoteModelAdapter());

      _userBox = await Hive.openBox<UserProfileModel>(AppConstants.userBoxName);
      _waterLogBox = await Hive.openBox<WaterLogModel>(AppConstants.waterLogBoxName);
      _bmiResultBox = await Hive.openBox<BmiResultModel>(AppConstants.bmiResultBoxName);
      _noteBox = await Hive.openBox<NoteModel>(AppConstants.noteBoxName);

      debugPrint('✅ Hive initialized successfully');
    } catch (e) {
      debugPrint('❌ Hive initialization error: $e');
      rethrow;
    }
  }

  static Box<UserProfileModel> getUserBox() => _userBox;
  static Box<WaterLogModel> getWaterLogBox() => _waterLogBox;
  static Box<BmiResultModel> getBmiResultBox() => _bmiResultBox;
  static Box<NoteModel> getNoteBox() => _noteBox;

  static Future<void> closeAll() async {
    await _userBox.close();
    await _waterLogBox.close();
    await _bmiResultBox.close();
    await _noteBox.close();
  }
}