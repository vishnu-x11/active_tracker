import 'package:hive/hive.dart';

part 'note_model.g.dart';

@HiveType(typeId: 4)
class NoteModel {
  @HiveField(0)
  final String dateKey; /// YYYY-MM-DD

  @HiveField(1)
  final String noteText;

  @HiveField(2)
  final String mood; /// 'happy', 'neutral', 'sad'

  @HiveField(3)
  final int fatigueLevel; /// 1-10

  @HiveField(4)
  final DateTime timestamp;

  NoteModel({
    required this.dateKey,
    required this.noteText,
    required this.mood,
    required this.fatigueLevel,
    required this.timestamp,
  });

  NoteModel copyWith({
    String? dateKey,
    String? noteText,
    String? mood,
    int? fatigueLevel,
    DateTime? timestamp,
  }) {
    return NoteModel(
      dateKey: dateKey ?? this.dateKey,
      noteText: noteText ?? this.noteText,
      mood: mood ?? this.mood,
      fatigueLevel: fatigueLevel ?? this.fatigueLevel,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}