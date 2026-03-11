import 'package:sqflite/sqflite.dart';
import 'database_helper.dart';

class SqliteManager {
  static late Database _database;

  static Future<void> init() async {
    try {
      _database = await DatabaseHelper().database;
      print('✅ SQLite initialized successfully');
    } catch (e) {
      print('❌ SQLite initialization failed: $e');
      rethrow;
    }
  }

  static Database getInstance() {
    return _database;
  }
}