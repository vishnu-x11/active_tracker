// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bmi_result_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BmiResultModelAdapter extends TypeAdapter<BmiResultModel> {
  @override
  final int typeId = 3;

  @override
  BmiResultModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BmiResultModel(
      userId: fields[0] as String,
      dateKey: fields[1] as String,
      bmi: fields[2] as double,
      weight: fields[3] as double,
      height: fields[4] as double,
      dailyCalories: fields[5] as double,
      proteinGrams: fields[6] as double,
      fatGrams: fields[7] as double,
      carbsGrams: fields[8] as double,
      bmiCategory: fields[9] as String,
      timestamp: fields[10] as DateTime,
      createdAt: fields[11] as DateTime,
      updatedAt: fields[12] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BmiResultModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.bmi)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.height)
      ..writeByte(5)
      ..write(obj.dailyCalories)
      ..writeByte(6)
      ..write(obj.proteinGrams)
      ..writeByte(7)
      ..write(obj.fatGrams)
      ..writeByte(8)
      ..write(obj.carbsGrams)
      ..writeByte(9)
      ..write(obj.bmiCategory)
      ..writeByte(10)
      ..write(obj.timestamp)
      ..writeByte(11)
      ..write(obj.createdAt)
      ..writeByte(12)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BmiResultModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
