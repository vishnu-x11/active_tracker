
part of 'water_log_model.dart';

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
      dateKey: fields[0] as String,
      totalIntake: fields[1] as double,
      timestamp: fields[2] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, WaterLogModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.totalIntake)
      ..writeByte(2)
      ..write(obj.timestamp);
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
