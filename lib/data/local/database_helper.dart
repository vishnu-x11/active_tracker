import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../config/constants.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.sqliteDbName);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables

    // 1. Food Logs Table
    await db.execute('''
      CREATE TABLE food_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        foodName TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        carbs REAL NOT NULL,
        quantity REAL NOT NULL,
        unit TEXT,
        timestamp INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, dateKey, foodName, timestamp)
      )
    ''');
    await db.execute('CREATE INDEX idx_food_logs_userId_dateKey ON food_logs(userId, dateKey)');

    // 2. Workout Logs Table
    await db.execute('''
      CREATE TABLE workout_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        workoutName TEXT NOT NULL,
        duration INTEGER NOT NULL,
        caloriesBurned REAL NOT NULL,
        intensity TEXT,
        notes TEXT,
        timestamp INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, dateKey, workoutName, timestamp)
      )
    ''');
    await db.execute('CREATE INDEX idx_workout_logs_userId_dateKey ON workout_logs(userId, dateKey)');

    // 3. Exercises Table
    await db.execute('''
      CREATE TABLE exercises (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        exerciseType TEXT NOT NULL,
        reps INTEGER NOT NULL,
        sets INTEGER NOT NULL,
        weight REAL,
        timestamp INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, dateKey, exerciseType, timestamp)
      )
    ''');
    await db.execute('CREATE INDEX idx_exercises_userId_dateKey ON exercises(userId, dateKey)');

    // 4. Body Weight Logs Table
    await db.execute('''
      CREATE TABLE body_weight_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        weight REAL NOT NULL,
        timestamp INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, dateKey)
      )
    ''');
    await db.execute('CREATE INDEX idx_body_weight_logs_userId_dateKey ON body_weight_logs(userId, dateKey)');

    // 5. Daily Log Summary Table
    await db.execute('''
      CREATE TABLE daily_log_summary (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        totalCalories REAL NOT NULL DEFAULT 0,
        totalProtein REAL NOT NULL DEFAULT 0,
        totalFat REAL NOT NULL DEFAULT 0,
        totalCarbs REAL NOT NULL DEFAULT 0,
        totalWater REAL NOT NULL DEFAULT 0,
        workoutMinutes INTEGER NOT NULL DEFAULT 0,
        pushups INTEGER NOT NULL DEFAULT 0,
        pullups INTEGER NOT NULL DEFAULT 0,
        mood TEXT,
        notes TEXT,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL,
        UNIQUE(userId, dateKey)
      )
    ''');
    await db.execute('CREATE INDEX idx_daily_log_summary_userId_dateKey ON daily_log_summary(userId, dateKey)');

    print('✅ All tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handle database upgrades in future versions
    if (oldVersion < newVersion) {
      // Migration logic here
    }
  }
}