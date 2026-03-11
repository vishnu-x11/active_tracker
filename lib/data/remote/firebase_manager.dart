import 'package:active_tracker/data/remote/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseManager {
  static Future<void> init() async {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print('✅ Firebase initialized successfully');
    } catch (e) {
      print('❌ Firebase initialization failed: $e');
      rethrow;
    }
  }
}