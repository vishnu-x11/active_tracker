import 'package:isar/isar.dart';

part 'exercise.g.dart';

@Collection()
class Exercise {
  Id? id;

  @Index(unique: true, type: IndexType.value)
  late String name;

  late String bodyPart;

  late bool isCustom;

  late DateTime dateAdded;

  late bool isActive;
}