import 'dart:async';
import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/diagnostics/rebuild_logger.dart';
import 'core/firebase/firebase_options.dart';
import 'core/providers/core_providers.dart';
import 'core/storage/app_database.dart';
import 'core/storage/legacy_cleanup.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e, st) {
    developer.log('Firebase init failed', error: e, stackTrace: st, name: 'startup');
  }

  final database = await AppDatabase.open();
  unawaited(LegacyCleanup.run());

  runApp(
    ProviderScope(
      observers: [if (kDebugMode) RebuildLogger()],
      overrides: [appDatabaseProvider.overrideWithValue(database)],
      child: const App(),
    ),
  );
}
