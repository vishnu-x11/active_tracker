// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'water_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WaterLogModelAdapter extends TypeAdapter<WaterLogModel> {
  @override
  final int typeId = 2;

  @override
  WaterLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WaterLogModel(
      userId: fields[0] as String,
      dateKey: fields[1] as String,
      mlConsumed: fields[2] as double,
      timestamp: fields[3] as DateTime,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WaterLogModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.dateKey)
      ..writeByte(2)
      ..write(obj.mlConsumed)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WaterLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
