import 'package:intl/intl.dart';

class DateUtils {
  // ============ DATE KEY FORMAT: YYYY-MM-DD ============
  // Used for grouping daily logs, food logs, workouts, etc.

  /// Get today's date key in format YYYY-MM-DD
  /// Always uses local timezone (never UTC)
  static String getDateKey({DateTime? date}) {
    final dateToUse = date ?? DateTime.now();
    return DateFormat('yyyy-MM-dd').format(dateToUse);
  }

  /// Get date key for a specific date
  static String getDateKeyForDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Get month key in format YYYY-MM for month queries
  static String getMonthKey({DateTime? date}) {
    final dateToUse = date ?? DateTime.now();
    return DateFormat('yyyy-MM').format(dateToUse);
  }

  /// Get year key in format YYYY for year queries
  static String getYearKey({DateTime? date}) {
    final dateToUse = date ?? DateTime.now();
    return DateFormat('yyyy').format(dateToUse);
  }

  /// Parse dateKey string back to DateTime
  static DateTime parseDateKey(String dateKey) {
    return DateTime.parse(dateKey);
  }

  /// Check if two date keys are the same day
  static bool isSameDay(String dateKey1, String dateKey2) {
    return dateKey1 == dateKey2;
  }

  /// Get formatted display date from dateKey
  /// Example: "2025-02-21" -> "Feb 21, 2025"
  static String formatDateKey(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateKey;
    }
  }

  /// Get formatted display date with day of week
  /// Example: "2025-02-21" -> "Friday, Feb 21"
  static String formatDateKeyWithDayOfWeek(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      return DateFormat('EEEE, MMM dd').format(date);
    } catch (e) {
      return dateKey;
    }
  }

  /// Get relative date description
  /// Example: Today, Yesterday, Tomorrow, or date if more than 2 days away
  static String getRelativeDate(String dateKey) {
    try {
      final date = DateTime.parse(dateKey);
      final today = DateTime.now();
      final yesterday = today.subtract(const Duration(days: 1));
      final tomorrow = today.add(const Duration(days: 1));

      if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(today)) {
        return 'Today';
      } else if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(yesterday)) {
        return 'Yesterday';
      } else if (DateFormat('yyyy-MM-dd').format(date) ==
          DateFormat('yyyy-MM-dd').format(tomorrow)) {
        return 'Tomorrow';
      } else {
        return formatDateKey(dateKey);
      }
    } catch (e) {
      return dateKey;
    }
  }

  /// Get time difference in human readable format
  /// Example: "2 hours ago", "3 days ago"
  static String getTimeDifference(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      return '$minutes minute${minutes > 1 ? 's' : ''} ago';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return '$hours hour${hours > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days day${days > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks week${weeks > 1 ? 's' : ''} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    }
  }

  /// Check if a dateKey is today
  static bool isToday(String dateKey) {
    return dateKey == getDateKey();
  }

  /// Check if a dateKey is in the past
  static bool isPast(String dateKey) {
    return DateTime.parse(dateKey).isBefore(DateTime.now());
  }

  /// Check if a dateKey is in the future
  static bool isFuture(String dateKey) {
    return DateTime.parse(dateKey).isAfter(DateTime.now());
  }

  /// Get list of dates between two date keys
  static List<String> getDatesBetween(String startDateKey, String endDateKey) {
    final startDate = DateTime.parse(startDateKey);
    final endDate = DateTime.parse(endDateKey);
    final dates = <String>[];

    for (var date = startDate;
    date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
    date = date.add(const Duration(days: 1))) {
      dates.add(getDateKeyForDate(date));
    }

    return dates;
  }

  /// Get first day of month for a given dateKey
  static String getFirstDayOfMonth(String dateKey) {
    final date = DateTime.parse(dateKey);
    final firstDay = DateTime(date.year, date.month, 1);
    return getDateKeyForDate(firstDay);
  }

  /// Get last day of month for a given dateKey
  static String getLastDayOfMonth(String dateKey) {
    final date = DateTime.parse(dateKey);
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return getDateKeyForDate(lastDay);
  }

  /// Get all days of month as list of dateKeys
  static List<String> getDaysOfMonth(String dateKey) {
    final date = DateTime.parse(dateKey);
    final firstDay = DateTime(date.year, date.month, 1);
    final lastDay = DateTime(date.year, date.month + 1, 0);

    return getDatesBetween(
      getDateKeyForDate(firstDay),
      getDateKeyForDate(lastDay),
    );
  }

  /// Format time of day
  /// Example: DateTime(2025, 2, 21, 14, 30) -> "2:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Format time with seconds
  /// Example: DateTime(2025, 2, 21, 14, 30, 45) -> "2:30:45 PM"
  static String formatTimeWithSeconds(DateTime dateTime) {
    return DateFormat('h:mm:ss a').format(dateTime);
  }
}