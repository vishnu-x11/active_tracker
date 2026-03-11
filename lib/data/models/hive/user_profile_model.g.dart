// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_profile_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileModelAdapter extends TypeAdapter<UserProfileModel> {
  @override
  final int typeId = 0;

  @override
  UserProfileModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfileModel(
      userId: fields[0] as String,
      name: fields[1] as String,
      age: fields[2] as int,
      weight: fields[3] as double,
      height: fields[4] as double,
      goalType: fields[5] as int,
      intensityLevel: fields[6] as int,
      calorieGoal: fields[7] as double,
      proteinGoal: fields[8] as double,
      fatGoal: fields[9] as double,
      carbsGoal: fields[10] as double,
      waterGoalMl: fields[11] as int,
      createdAt: fields[12] as DateTime,
      updatedAt: fields[13] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfileModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.age)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.goalType)
      ..writeByte(6)
      ..write(obj.intensityLevel)
      ..writeByte(7)
      ..write(obj.calorieGoal)
      ..writeByte(8)
      ..write(obj.proteinGoal)
      ..writeByte(9)
      ..write(obj.fatGoal)
      ..writeByte(10)
      ..write(obj.carbsGoal)
      ..writeByte(11)
      ..write(obj.waterGoalMl)
      ..writeByte(12)
      ..write(obj.createdAt)
      ..writeByte(13)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
