
part of 'bmi_result_model.dart';


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
      dateKey: fields[0] as String,
      bmi: fields[1] as double,
      kcal: fields[2] as double,
      proteinTarget: fields[3] as double,
      fatTarget: fields[4] as double,
      carbsTarget: fields[5] as double,
      goalType: fields[6] as int,
      intensity: fields[7] as int,
      createdAt: fields[8] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, BmiResultModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.dateKey)
      ..writeByte(1)
      ..write(obj.bmi)
      ..writeByte(2)
      ..write(obj.kcal)
      ..writeByte(3)
      ..write(obj.proteinTarget)
      ..writeByte(4)
      ..write(obj.fatTarget)
      ..writeByte(5)
      ..write(obj.carbsTarget)
      ..writeByte(6)
      ..write(obj.goalType)
      ..writeByte(7)
      ..write(obj.intensity)
      ..writeByte(8)
      ..write(obj.createdAt);
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
