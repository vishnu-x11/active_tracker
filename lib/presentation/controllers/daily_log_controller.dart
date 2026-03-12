import 'package:get/get.dart';
import 'package:active_tracker/data/models/sqlite/daily_log_summary.dart';
import 'package:active_tracker/domain/repositories/repositories.dart';
import 'package:active_tracker/utils/date_utils.dart';

/// Manages daily log summaries and mood tracking
class DailyLogController extends GetxController {
  // ============ DEPENDENCIES ============
  final DailyLogRepository _repository;

  // ============ OBSERVABLE STATE ============
  final dailySummary = Rx<DailyLogSummary?>(null);
  final goalsMetStatus = <String, bool>{}.obs;
  final isLoading = false.obs;
  final errorMessage = ''.obs;
  final selectedDate = DateTime.now().obs;
  final mood = ''.obs;
  final notes = ''.obs;

  // ============ CONSTRUCTOR ============
  DailyLogController(this._repository);

  // ============ LIFECYCLE ============
  @override
  void onInit() {
    super.onInit();
    print('✅ DailyLogController initialized');
    loadDailyLog();

    // Watch for date changes
    ever(selectedDate, (_) {
      loadDailyLog();
    });
  }

  @override
  void onReady() {
    super.onReady();
    print('✅ DailyLogController ready');
  }

  @override
  void onClose() {
    super.onClose();
    print('✅ DailyLogController closed');
  }

  // ============ BUSINESS LOGIC ============

  /// Load daily log for selected date
  Future<void> loadDailyLog() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);

      final summary = await _repository.getDailyLogSummaryForDate(dateKey);
      dailySummary.value = summary;

      final goalsStatus = await _repository.getGoalsMet(dateKey);
      goalsMetStatus.assignAll(goalsStatus);

      mood.value = summary?.mood ?? '';
      notes.value = summary?.notes ?? '';

      print('✅ Daily log loaded for $dateKey');
    } catch (e) {
      errorMessage.value = 'Failed to load daily log: $e';
      print('❌ Daily log error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  /// Update mood
  Future<void> updateMood(String newMood) async {
    try {
      isLoading.value = true;

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _repository.updateDailyMood(dateKey, newMood);
      mood.value = newMood;

      print('✅ Mood updated: $newMood');
    } catch (e) {
      errorMessage.value = 'Failed to update mood: $e';
      print('❌ Error updating mood: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Update notes
  Future<void> updateNotes(String newNotes) async {
    try {
      isLoading.value = true;

      final dateKey = DateUtils.getDateKey(date: selectedDate.value);
      await _repository.updateDailyNotes(dateKey, newNotes);
      notes.value = newNotes;

      print('✅ Notes updated');
    } catch (e) {
      errorMessage.value = 'Failed to update notes: $e';
      print('❌ Error updating notes: $e');
      rethrow;
    } finally {
      isLoading.value = false;
    }
  }

  /// Get all daily data summary
  Future<void> refreshDailyLog() async {
    await loadDailyLog();
  }

  // ============ HELPER METHODS ============

  /// Navigate to previous day
  void previousDay() {
    selectedDate.value = selectedDate.value.subtract(const Duration(days: 1));
  }

  /// Navigate to next day
  void nextDay() {
    selectedDate.value = selectedDate.value.add(const Duration(days: 1));
  }

  /// Go to today
  void goToday() {
    selectedDate.value = DateTime.now();
  }

  /// Get formatted date
  String getSelectedDateString() {
    final dateKey = DateUtils.getDateKey(date: selectedDate.value);
    return DateUtils.formatDateKey(dateKey);
  }

  /// Get number of goals met
  int getGoalsMetCount() {
    return goalsMetStatus.values.where((met) => met).length;
  }

  /// Get goals met string
  String getGoalsMetString() => '${getGoalsMetCount()}/4 goals met';

  /// Check if specific goal is met
  bool isGoalMet(String goal) {
    return goalsMetStatus[goal] ?? false;
  }

  /// Get mood emoji
  String getMoodEmoji() {
    switch (mood.value.toLowerCase()) {
      case 'excellent':
      case 'amazing':
        return '😄';
      case 'good':
      case 'great':
        return '😊';
      case 'okay':
      case 'normal':
        return '😐';
      case 'bad':
      case 'poor':
        return '😔';
      case 'terrible':
      case 'awful':
        return '😢';
      default:
        return '❓';
    }
  }

  /// Get mood color
  String getMoodColor() {
    switch (mood.value.toLowerCase()) {
      case 'excellent':
      case 'amazing':
        return '#4CAF50'; // Green
      case 'good':
      case 'great':
        return '#8BC34A'; // Light green
      case 'okay':
      case 'normal':
        return '#FFC107'; // Yellow
      case 'bad':
      case 'poor':
        return '#FF9800'; // Orange
      case 'terrible':
      case 'awful':
        return '#F44336'; // Red
      default:
        return '#9C27B0'; // Purple
    }
  }

  /// Get goals summary
  String getGoalsSummary() {
    final metCount = getGoalsMetCount();

    switch (metCount) {
      case 0:
        return '⏳ Start working on your goals!';
      case 1:
        return '🔥 Great start! Keep going!';
      case 2:
        return '💪 Halfway there! Finish strong!';
      case 3:
        return '🎯 Almost perfect! One more to go!';
      case 4:
        return '🏆 All goals met! Excellent work!';
      default:
        return 'Keep up the good work!';
    }
  }

  /// Get daily achievement message
  String getDailyAchievementMessage() {
    final metCount = getGoalsMetCount();
    final mood = this.mood.value;

    if (metCount == 4 && mood.toLowerCase().contains('good')) {
      return '🌟 Perfect day! You\'ve exceeded expectations!';
    } else if (metCount == 4) {
      return '🎉 All goals met! Great performance!';
    } else if (metCount >= 3) {
      return '✨ Excellent progress today!';
    } else if (metCount >= 2) {
      return '💪 Good effort! Keep pushing!';
    } else if (metCount >= 1) {
      return '🚀 You\'re on your way!';
    } else {
      return '💡 Start your journey today!';
    }
  }

  /// Get notes placeholder
  String getNotesPlaceholder() {
    return 'How was your day? Any notes or observations?';
  }

  /// Check if daily log has been created
  bool isDailyLogCreated() {
    return dailySummary.value != null;
  }

  /// Get last update time
  String getLastUpdateTime() {
    if (dailySummary.value == null) return 'No data';

    final lastUpdate = dailySummary.value!.updatedAt;
    final now = DateTime.now().millisecondsSinceEpoch;
    final difference = Duration(milliseconds: now - lastUpdate);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}