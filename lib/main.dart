import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'config/constants.dart';
import 'config/routes.dart';
import 'config/theme.dart';
import 'data/local/hive_manager.dart';
import 'data/local/sqlite_manager.dart';
import 'data/remote/firebase_manager.dart';
import 'data/sync/connectivity_monitor.dart';
import 'data/sync/sync_manager.dart';
import 'presentation/bindings/app_binding.dart';

void main() async {
  // ============ STEP 1: Ensure Flutter Bindings ============
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ============ STEP 2: Initialize Hive (User Preferences) ============
    await HiveManager.init();
    print('✅ Hive initialized successfully');

    // ============ STEP 3: Initialize SQLite (Local Cache) ============
    await SqliteManager.init();

    // ============ STEP 4: Initialize Firebase (Cloud Backend) ============
    await FirebaseManager.init();

    // ============ STEP 5: Initialize Sync Infrastructure ============
    await ConnectivityMonitor().init();
    await SyncManager().init();

    print('✅ All databases and sync infrastructure initialized successfully');
  } catch (e) {
    print('❌ Database initialization failed: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      // ============ APP CONFIGURATION ============
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // ============ THEMING ============
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,

      // ============ ROUTING ============
      initialRoute: AppRoutes.splash,
      getPages: appPages,
      initialBinding: AppBinding(),

      // ============ LOCALIZATION ============
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),

      // ============ TRANSITIONS ============
      defaultTransition: Transition.fade,
      transitionDuration: const Duration(milliseconds: 200),

      // ============ NAVIGATION ============
      navigatorObservers: [],
    );
  }
}