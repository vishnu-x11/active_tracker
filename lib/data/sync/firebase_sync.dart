import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:active_tracker/data/models/sqlite/food_log.dart';
import 'package:active_tracker/data/models/sqlite/workout_log.dart';
import 'package:active_tracker/data/models/sqlite/exercise.dart';
import 'package:active_tracker/data/models/sqlite/body_weight_log.dart';
import 'package:active_tracker/data/models/sqlite/daily_log_summary.dart';

/// Handles Firebase real-time sync and data operations
class FirebaseSync {
  static final FirebaseSync _instance = FirebaseSync._internal();

  factory FirebaseSync() {
    return _instance;
  }

  FirebaseSync._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Store listeners for cleanup
  final Map<String, StreamSubscription> _listeners = {};

  /// Initialize Firebase sync
  Future<void> init() async {
    try {
      // Configure Firestore settings
      await _firestore.enableNetwork();
      print('✅ Firebase Sync initialized');
    } catch (e) {
      print('❌ Error initializing Firebase sync: $e');
    }
  }

  // ============ FOOD LOGS ============

  /// Listen to food logs for user
  void listenToFoodLogs(
      String userId,
      String dateKey,
      Function(List<FoodLog>) onUpdate,
      ) {
    try {
      final key = 'foodLogs_$userId\_$dateKey';

      _listeners[key] = _firestore
          .collection('foodLogs')
          .where('userId', isEqualTo: userId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots()
          .listen((snapshot) {
        try {
          final logs = snapshot.docs
              .map((doc) => FoodLog.fromMap({
            ...doc.data(),
            'id': doc.id,
          }))
              .toList();

          onUpdate(logs);
          print('✅ Food logs updated: ${logs.length} items');
        } catch (e) {
          print('❌ Error processing food logs: $e');
        }
      });
    } catch (e) {
      print('❌ Error listening to food logs: $e');
    }
  }

  /// Push food log to Firebase
  Future<String> pushFoodLog(FoodLog foodLog) async {
    try {
      final docRef = await _firestore.collection('foodLogs').add({
        ...foodLog.toMap(),
        'userId': foodLog.userId,
        'dateKey': foodLog.dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Food log pushed: ${foodLog.foodName}');
      return docRef.id;
    } catch (e) {
      print('❌ Error pushing food log: $e');
      rethrow;
    }
  }

  /// Pull food logs from Firebase
  Future<List<FoodLog>> pullFoodLogs(
      String userId,
      String dateKey,
      ) async {
    try {
      final snapshot = await _firestore
          .collection('foodLogs')
          .where('userId', isEqualTo: userId)
          .where('dateKey', isEqualTo: dateKey)
          .get();

      final logs = snapshot.docs
          .map((doc) => FoodLog.fromMap({
        ...doc.data(),
        'id': doc.id,
      }))
          .toList();

      print('✅ Pulled ${logs.length} food logs');
      return logs;
    } catch (e) {
      print('❌ Error pulling food logs: $e');
      return [];
    }
  }

  // ============ WORKOUT LOGS ============

  /// Listen to workout logs for user
  void listenToWorkoutLogs(
      String userId,
      String dateKey,
      Function(List<WorkoutLog>) onUpdate,
      ) {
    try {
      final key = 'workoutLogs_$userId\_$dateKey';

      _listeners[key] = _firestore
          .collection('workoutLogs')
          .where('userId', isEqualTo: userId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots()
          .listen((snapshot) {
        try {
          final logs = snapshot.docs
              .map((doc) => WorkoutLog.fromMap({
            ...doc.data(),
            'id': doc.id,
          }))
              .toList();

          onUpdate(logs);
          print('✅ Workout logs updated: ${logs.length} items');
        } catch (e) {
          print('❌ Error processing workout logs: $e');
        }
      });
    } catch (e) {
      print('❌ Error listening to workout logs: $e');
    }
  }

  /// Push workout log to Firebase
  Future<String> pushWorkoutLog(WorkoutLog workoutLog) async {
    try {
      final docRef = await _firestore.collection('workoutLogs').add({
        ...workoutLog.toMap(),
        'userId': workoutLog.userId,
        'dateKey': workoutLog.dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Workout log pushed: ${workoutLog.workoutName}');
      return docRef.id;
    } catch (e) {
      print('❌ Error pushing workout log: $e');
      rethrow;
    }
  }

  // ============ EXERCISES ============

  /// Listen to exercises for user
  void listenToExercises(
      String userId,
      String dateKey,
      Function(List<Exercise>) onUpdate,
      ) {
    try {
      final key = 'exercises_$userId\_$dateKey';

      _listeners[key] = _firestore
          .collection('exercises')
          .where('userId', isEqualTo: userId)
          .where('dateKey', isEqualTo: dateKey)
          .snapshots()
          .listen((snapshot) {
        try {
          final exercises = snapshot.docs
              .map((doc) => Exercise.fromMap({
            ...doc.data(),
            'id': doc.id,
          }))
              .toList();

          onUpdate(exercises);
          print('✅ Exercises updated: ${exercises.length} items');
        } catch (e) {
          print('❌ Error processing exercises: $e');
        }
      });
    } catch (e) {
      print('❌ Error listening to exercises: $e');
    }
  }

  /// Push exercise to Firebase
  Future<String> pushExercise(Exercise exercise) async {
    try {
      final docRef = await _firestore.collection('exercises').add({
        ...exercise.toMap(),
        'userId': exercise.userId,
        'dateKey': exercise.dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Exercise pushed: ${exercise.exerciseType}');
      return docRef.id;
    } catch (e) {
      print('❌ Error pushing exercise: $e');
      rethrow;
    }
  }

  // ============ BODY WEIGHT LOGS ============

  /// Push body weight log to Firebase
  Future<String> pushBodyWeightLog(BodyWeightLog log) async {
    try {
      final docRef = await _firestore.collection('bodyWeightLogs').add({
        ...log.toMap(),
        'userId': log.userId,
        'dateKey': log.dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Body weight log pushed: ${log.weight}kg');
      return docRef.id;
    } catch (e) {
      print('❌ Error pushing body weight log: $e');
      rethrow;
    }
  }

  // ============ DAILY LOG SUMMARIES ============

  /// Push daily log summary to Firebase
  Future<String> pushDailyLogSummary(DailyLogSummary summary) async {
    try {
      final docRef = await _firestore.collection('dailyLogSummaries').add({
        ...summary.toMap(),
        'userId': summary.userId,
        'dateKey': summary.dateKey,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Daily log summary pushed: ${summary.dateKey}');
      return docRef.id;
    } catch (e) {
      print('❌ Error pushing daily log summary: $e');
      rethrow;
    }
  }

  // ============ LISTENER MANAGEMENT ============

  /// Stop listening to specific collection
  void stopListening(String key) {
    try {
      _listeners[key]?.cancel();
      _listeners.remove(key);
      print('✅ Listener stopped: $key');
    } catch (e) {
      print('❌ Error stopping listener: $e');
    }
  }

  /// Stop all listeners
  void stopAllListeners() {
    try {
      for (final listener in _listeners.values) {
        listener.cancel();
      }
      _listeners.clear();
      print('✅ All listeners stopped');
    } catch (e) {
      print('❌ Error stopping listeners: $e');
    }
  }

  /// Get active listeners count
  int get activeListenersCount => _listeners.length;

  // ============ HELPER METHODS ============

  /// Enable offline persistence
  Future<void> enableOfflinePersistence() async {
    try {
      await _firestore.enableNetwork();
      print('✅ Offline persistence enabled');
    } catch (e) {
      print('⚠️ Offline persistence not available: $e');
    }
  }

  /// Disable offline persistence
  Future<void> disableOfflinePersistence() async {
    try {
      await _firestore.disableNetwork();
      print('✅ Offline persistence disabled');
    } catch (e) {
      print('⚠️ Error disabling offline persistence: $e');
    }
  }
}

/// Extension to add fromMap for models
extension on FoodLog {
  static FoodLog fromMap(Map<String, dynamic> map) {
    return FoodLog(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id'].toString()),
      userId: map['userId'] as String,
      dateKey: map['dateKey'] as String,
      foodName: map['foodName'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      carbs: (map['carbs'] as num).toDouble(),
      quantity: (map['quantity'] as num).toDouble(),
      unit: map['unit'] as String?,
      timestamp: map['timestamp'] as int,
      createdAt: map['createdAt'] as int,
      updatedAt: map['updatedAt'] as int,
    );
  }
}