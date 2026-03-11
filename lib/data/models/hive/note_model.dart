import 'package:hive/hive.dart';

part 'note_model.g.dart';

/// Daily notes/journal stored in Hive (non-synced)
/// TypeId: 4 - CRITICAL: Never change or reuse this ID
@HiveType(typeId: 4)
class NoteModel extends HiveObject {
  @HiveField(0)
  final String userId;

  @HiveField(1)
  final String dateKey; // Format: "2025-02-21"

  @HiveField(2)
  final String content;

  @HiveField(3)
  final String? mood; // "happy", "neutral", "sad"

  @HiveField(4)
  final String? tags; // Comma-separated tags

  @HiveField(5)
  final DateTime timestamp;

  @HiveField(6)
  final DateTime createdAt;

  @HiveField(7)
  final DateTime updatedAt;

  NoteModel({
    required this.userId,
    required this.dateKey,
    required this.content,
    this.mood,
    this.tags,
    required this.timestamp,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of this model with updated fields
  NoteModel copyWith({
    String? userId,
    String? dateKey,
    String? content,
    String? mood,
    String? tags,
    DateTime? timestamp,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      userId: userId ?? this.userId,
      dateKey: dateKey ?? this.dateKey,
      content: content ?? this.content,
      mood: mood ?? this.mood,
      tags: tags ?? this.tags,
      timestamp: timestamp ?? this.timestamp,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Get mood emoji
  String getMoodEmoji() {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'neutral':
      default:
        return '😐';
    }
  }

  /// Get tags as list
  List<String> getTagsList() {
    if (tags == null || tags!.isEmpty) {
      return [];
    }
    return tags!.split(',').map((e) => e.trim()).toList();
  }

  @override
  String toString() {
    return 'NoteModel(userId: $userId, dateKey: $dateKey, mood: $mood, content: ${content.substring(0, 30)}...)';
  }
}