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
      version: 9,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create all tables
    await _createTables(db);
  }

  Future<void> _createTables(Database db) async {
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
        mealType TEXT NOT NULL DEFAULT 'Breakfast',
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
        category TEXT NOT NULL DEFAULT 'General',
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
        totalCaloriesBurned REAL NOT NULL DEFAULT 0,
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

    // 6. Sync Queue Table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        operationType TEXT NOT NULL,
        tableName TEXT NOT NULL,
        entityId TEXT NOT NULL,
        data TEXT NOT NULL,
        retryCount INTEGER DEFAULT 0,
        createdAt INTEGER NOT NULL,
        lastRetryAt INTEGER
      )
    ''');
    await db.execute('CREATE INDEX idx_sync_queue_userId ON sync_queue(userId)');

    // 7. Food Items (Library)
    await db.execute('''
      CREATE TABLE food_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        fat REAL NOT NULL,
        carbs REAL NOT NULL,
        unit TEXT NOT NULL DEFAULT 'g',
        category TEXT NOT NULL DEFAULT 'General'
      )
    ''');
    await db.execute('CREATE INDEX idx_food_items_name ON food_items(name)');

    // 8. Exercise Definitions (Library)
    await db.execute('''
      CREATE TABLE exercise_definitions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        isBodyweight INTEGER NOT NULL DEFAULT 0,
        description TEXT
      )
    ''');
    await db.execute('CREATE INDEX idx_exercise_definitions_name ON exercise_definitions(name)');

    // Pre-populate libraries
    await _prePopulateLibraries(db);

    // 9. Workout Programs (New in v4.0)
    await db.execute('''
      CREATE TABLE workout_programs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        difficulty TEXT NOT NULL,
        goal TEXT NOT NULL,
        exercises_list TEXT NOT NULL,
        duration_weeks INTEGER NOT NULL
      )
    ''');

    // 10. Recipes (New in v4.0)
    await db.execute('''
      CREATE TABLE recipes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        calories REAL NOT NULL,
        protein REAL NOT NULL,
        carbs REAL NOT NULL,
        fat REAL NOT NULL,
        ingredients TEXT NOT NULL,
        cookTime INTEGER NOT NULL
      )
    ''');

    // 11. Meal Plans (New in v4.0)
    await db.execute('''
      CREATE TABLE meal_plans (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        goal TEXT NOT NULL,
        targetMacros TEXT NOT NULL,
        meals TEXT NOT NULL
      )
    ''');

    // 12. User Goals (New in v4.0)
    await db.execute('''
      CREATE TABLE user_goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        type TEXT NOT NULL,
        target REAL NOT NULL,
        startDate INTEGER NOT NULL,
        targetDate INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // 13. Achievements (New in v4.0)
    await db.execute('''
      CREATE TABLE achievements (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        points INTEGER NOT NULL,
        criteria TEXT NOT NULL
      )
    ''');

    // 14. User Badges (New in v4.0)
    await db.execute('''
      CREATE TABLE user_badges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        badgeId INTEGER NOT NULL,
        unlockedAt INTEGER NOT NULL
      )
    ''');

    // 15. Streaks (New in v4.0)
    await db.execute('''
      CREATE TABLE streaks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        currentStreak INTEGER NOT NULL DEFAULT 0,
        longestStreak INTEGER NOT NULL DEFAULT 0,
        lastLogDate TEXT NOT NULL,
        UNIQUE(userId)
      )
    ''');

    // 16. Friend Connections (New in v4.0)
    await db.execute('''
      CREATE TABLE friend_connections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        friendId TEXT NOT NULL,
        connectedAt INTEGER NOT NULL,
        status TEXT NOT NULL
      )
    ''');

    // 17. Challenges (New in v4.0)
    await db.execute('''
      CREATE TABLE challenges (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        goal TEXT NOT NULL,
        duration INTEGER NOT NULL,
        participants TEXT NOT NULL
      )
    ''');

    // 18. Analytics Cache (New in v4.0)
    await db.execute('''
      CREATE TABLE analytics_cache (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        totalCalories REAL NOT NULL,
        macros TEXT NOT NULL,
        workoutCount INTEGER NOT NULL,
        bmiBoundary TEXT NOT NULL,
        UNIQUE(userId, dateKey)
      )
    ''');

    // 19. Body Metrics (New in v4.0)
    await db.execute('''
      CREATE TABLE body_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        dateKey TEXT NOT NULL,
        bodyFat REAL,
        leanMass REAL,
        measurements TEXT,
        UNIQUE(userId, dateKey)
      )
    ''');

    // 20. Device Integrations (New in v4.0)
    await db.execute('''
      CREATE TABLE device_integrations (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        deviceType TEXT NOT NULL,
        apiToken TEXT,
        syncStatus TEXT NOT NULL,
        UNIQUE(userId, deviceType)
      )
    ''');

    print('✅ All tables created including v4.0 features');
  }

  Future<void> _prePopulateLibraries(Database db) async {
    // Basic Food Items
    final foods = [
      ['Chicken Breast', 165, 31, 3.6, 0, 'g', 'Protein'],
      ['White Rice', 130, 2.7, 0.3, 28, 'g', 'Carbs'],
      ['Brown Rice', 111, 2.6, 0.9, 23, 'g', 'Carbs'],
      ['Whole Egg', 155, 13, 11, 1.1, 'g', 'Protein'],
      ['Oats', 389, 16.9, 6.9, 66, 'g', 'Carbs'],
      ['Peanut Butter', 588, 25, 50, 20, 'g', 'Fats'],
      ['Apple', 52, 0.3, 0.2, 14, 'g', 'Fruit'],
      ['Banana', 89, 1.1, 0.3, 23, 'g', 'Fruit'],
      ['Broccoli', 34, 2.8, 0.4, 7, 'g', 'Vegetables'],
      ['Greek Yogurt', 59, 10, 0.4, 3.6, 'g', 'Protein'],
    ];

    for (var f in foods) {
      await db.insert('food_items', {
        'name': f[0],
        'calories': f[1],
        'protein': f[2],
        'fat': f[3],
        'carbs': f[4],
        'unit': f[5],
        'category': f[6],
      });
    }

    // Basic Exercise Definitions categorized by body parts
    final exercises = [
      // Shoulder
      ['Shoulder Press', 'Shoulder', 0, 'Overhead press'],
      ['Lateral Raises', 'Shoulder', 0, 'Dumbbell lateral raises'],
      ['Front Raises', 'Shoulder', 0, 'Dumbbell front raises'],
      ['Face Pulls', 'Shoulder', 0, 'Cable face pulls'],
      
      // Triceps
      ['Tricep Extensions', 'Triceps', 0, 'Overhead dumbbell extensions'],
      ['Skull Crushers', 'Triceps', 0, 'EZ bar skull crushers'],
      ['Dips', 'Triceps', 1, 'Bodyweight or weighted dips'],
      ['Pushdowns', 'Triceps', 0, 'Cable tricep pushdowns'],
      
      // Biceps
      ['Bicep Curls', 'Biceps', 0, 'Dumbbell bicep curls'],
      ['Hammer Curls', 'Biceps', 0, 'Neutral grip curls'],
      ['Preacher Curls', 'Biceps', 0, 'EZ bar curls on preacher bench'],
      ['Concentration Curls', 'Biceps', 0, 'Single arm curls'],
      
      // Fore Arms
      ['Wrist Curls', 'Fore Arms', 0, 'Dumbbell wrist curls'],
      ['Reverse Wrist Curls', 'Fore Arms', 0, 'Dumbbell reverse curls'],
      ['Farmers Walk', 'Fore Arms', 0, 'Grip strength walk'],
      
      // Back
      ['Pullups', 'Pullups', 1, 'Standard pullups'],
      ['Deadlift', 'Back', 0, 'Barbell deadlift'],
      ['Bent Over Rows', 'Back', 0, 'Barbell or dumbbell rows'],
      ['Lat Pulldown', 'Back', 0, 'Cable lat pulldown'],
      ['T-Bar Rows', 'Back', 0, 'Machine or bar rows'],
      
      // Leg
      ['Squats', 'Leg', 1, 'Bodyweight or barbell squats'],
      ['Leg Press', 'Leg', 0, 'Machine leg press'],
      ['Lunges', 'Leg', 1, 'Walking or stationary lunges'],
      ['Leg Extensions', 'Leg', 0, 'Machine leg extensions'],
      ['Leg Curls', 'Leg', 0, 'Machine leg curls'],
      ['Calf Raises', 'Leg', 0, 'Standing or seated calf raises'],
      
      // Abs
      ['Plank', 'Abs', 1, 'Core plank'],
      ['Crunches', 'Abs', 1, 'Standard abdominal crunches'],
      ['Leg Raises', 'Abs', 1, 'Hanging or lying leg raises'],
      ['Russian Twists', 'Abs', 1, 'Core twist exercise'],
      
      // General/Other
      ['Pushups', 'Pushups', 1, 'Standard pushups'],
      ['Running', 'Cardio', 0, 'Jogging or running'],
      ['Cycling', 'Cardio', 0, 'Indoor or outdoor cycling'],
      ['Bench Press', 'Chest', 0, 'Barbell bench press'],
    ];

    for (var ex in exercises) {
      await db.insert('exercise_definitions', {
        'name': ex[0],
        'category': ex[1],
        'isBodyweight': ex[2],
        'description': ex[3],
      });
    }
    print('✅ Library pre-populated');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS sync_queue (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          operationType TEXT NOT NULL,
          tableName TEXT NOT NULL,
          entityId TEXT NOT NULL,
          data TEXT NOT NULL,
          retryCount INTEGER DEFAULT 0,
          createdAt INTEGER NOT NULL,
          lastRetryAt INTEGER
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_userId ON sync_queue(userId)');
      print('✅ Database upgraded to version 2: sync_queue table added');
    }

    if (oldVersion < 3) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS food_items (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          fat REAL NOT NULL,
          carbs REAL NOT NULL,
          unit TEXT NOT NULL DEFAULT 'g',
          category TEXT NOT NULL DEFAULT 'General'
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_food_items_name ON food_items(name)');

      await db.execute('''
        CREATE TABLE IF NOT EXISTS exercise_definitions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          category TEXT NOT NULL,
          isBodyweight INTEGER NOT NULL DEFAULT 0,
          description TEXT
        )
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exercise_definitions_name ON exercise_definitions(name)');

      await _prePopulateLibraries(db);
      print('✅ Database upgraded to version 3: Library tables added');
    }

    if (oldVersion < 4) {
      await db.delete('exercise_definitions');
      await _prePopulateLibraries(db);
      print('✅ Database upgraded to version 4: Library re-populated with categories');
    }

    if (oldVersion < 5) {
      await db.delete('exercise_definitions');
      await _prePopulateLibraries(db);
      print('✅ Database upgraded to version 5: Library re-populated with Pushups/Pullups categories');
    }

    if (oldVersion < 6) {
      final tables = await db.rawQuery("PRAGMA table_info(exercises)");
      if (!tables.any((column) => column['name'] == 'category')) {
        await db.execute('ALTER TABLE exercises ADD COLUMN category TEXT NOT NULL DEFAULT "General"');
        print('✅ Database upgraded to version 6: category column added to exercises');
      }
    }

    if (oldVersion < 7) {
      final tables = await db.rawQuery("PRAGMA table_info(daily_log_summary)");
      if (!tables.any((column) => column['name'] == 'totalCaloriesBurned')) {
        await db.execute('ALTER TABLE daily_log_summary ADD COLUMN totalCaloriesBurned REAL NOT NULL DEFAULT 0');
        print('✅ Database upgraded to version 7: totalCaloriesBurned column added');
      }
    }

    if (oldVersion < 8) {
      // 9. Workout Programs
      await db.execute('''
        CREATE TABLE IF NOT EXISTS workout_programs (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          difficulty TEXT NOT NULL,
          goal TEXT NOT NULL,
          exercises_list TEXT NOT NULL,
          duration_weeks INTEGER NOT NULL
        )
      ''');

      // 10. Recipes
      await db.execute('''
        CREATE TABLE IF NOT EXISTS recipes (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          calories REAL NOT NULL,
          protein REAL NOT NULL,
          carbs REAL NOT NULL,
          fat REAL NOT NULL,
          ingredients TEXT NOT NULL,
          cookTime INTEGER NOT NULL
        )
      ''');

      // 11. Meal Plans
      await db.execute('''
        CREATE TABLE IF NOT EXISTS meal_plans (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          goal TEXT NOT NULL,
          targetMacros TEXT NOT NULL,
          meals TEXT NOT NULL
        )
      ''');

      // 12. User Goals
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_goals (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          type TEXT NOT NULL,
          target REAL NOT NULL,
          startDate INTEGER NOT NULL,
          targetDate INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');

      // 13. Achievements
      await db.execute('''
        CREATE TABLE IF NOT EXISTS achievements (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          description TEXT NOT NULL,
          points INTEGER NOT NULL,
          criteria TEXT NOT NULL
        )
      ''');

      // 14. User Badges
      await db.execute('''
        CREATE TABLE IF NOT EXISTS user_badges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          badgeId INTEGER NOT NULL,
          unlockedAt INTEGER NOT NULL
        )
      ''');

      // 15. Streaks
      await db.execute('''
        CREATE TABLE IF NOT EXISTS streaks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          currentStreak INTEGER NOT NULL DEFAULT 0,
          longestStreak INTEGER NOT NULL DEFAULT 0,
          lastLogDate TEXT NOT NULL,
          UNIQUE(userId)
        )
      ''');

      // 16. Friend Connections
      await db.execute('''
        CREATE TABLE IF NOT EXISTS friend_connections (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          friendId TEXT NOT NULL,
          connectedAt INTEGER NOT NULL,
          status TEXT NOT NULL
        )
      ''');

      // 17. Challenges
      await db.execute('''
        CREATE TABLE IF NOT EXISTS challenges (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          goal TEXT NOT NULL,
          duration INTEGER NOT NULL,
          participants TEXT NOT NULL
        )
      ''');

      // 18. Analytics Cache
      await db.execute('''
        CREATE TABLE IF NOT EXISTS analytics_cache (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          dateKey TEXT NOT NULL,
          totalCalories REAL NOT NULL,
          macros TEXT NOT NULL,
          workoutCount INTEGER NOT NULL,
          bmiBoundary TEXT NOT NULL,
          UNIQUE(userId, dateKey)
        )
      ''');

      // 19. Body Metrics
      await db.execute('''
        CREATE TABLE IF NOT EXISTS body_metrics (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          dateKey TEXT NOT NULL,
          bodyFat REAL,
          leanMass REAL,
          measurements TEXT,
          UNIQUE(userId, dateKey)
        )
      ''');

      // 20. Device Integrations
      await db.execute('''
        CREATE TABLE IF NOT EXISTS device_integrations (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          userId TEXT NOT NULL,
          deviceType TEXT NOT NULL,
          apiToken TEXT,
          syncStatus TEXT NOT NULL,
          UNIQUE(userId, deviceType)
        )
      ''');

      print('✅ Database upgraded to version 8: v4.0 tables added');
    }

    if (oldVersion < 9) {
      final tables = await db.rawQuery("PRAGMA table_info(food_logs)");
      if (!tables.any((column) => column['name'] == 'mealType')) {
        await db.execute("ALTER TABLE food_logs ADD COLUMN mealType TEXT NOT NULL DEFAULT 'Breakfast'");
        print('✅ Database upgraded to version 9: mealType column added to food_logs');
      }
    }
  }
}