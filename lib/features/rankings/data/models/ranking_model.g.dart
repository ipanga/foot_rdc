// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ranking_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RankingModelAdapter extends TypeAdapter<RankingModel> {
  @override
  final int typeId = 1;

  @override
  RankingModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RankingModel(
      id: fields[0] as int,
      title: fields[1] as String,
      data: (fields[2] as Map).cast<String, TeamData>(),
    );
  }

  @override
  void write(BinaryWriter writer, RankingModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.data);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RankingModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TeamDataModelAdapter extends TypeAdapter<TeamDataModel> {
  @override
  final int typeId = 2;

  @override
  TeamDataModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TeamDataModel(
      p: fields[0] as String?,
      w: fields[1] as String?,
      d: fields[2] as String?,
      ptwo: fields[3] as String?,
      f: fields[4] as String?,
      a: fields[5] as String?,
      gd: fields[6] as String?,
      pts: fields[7] as String?,
      name: fields[8] as String,
      pos: fields[9] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TeamDataModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.p)
      ..writeByte(1)
      ..write(obj.w)
      ..writeByte(2)
      ..write(obj.d)
      ..writeByte(3)
      ..write(obj.ptwo)
      ..writeByte(4)
      ..write(obj.f)
      ..writeByte(5)
      ..write(obj.a)
      ..writeByte(6)
      ..write(obj.gd)
      ..writeByte(7)
      ..write(obj.pts)
      ..writeByte(8)
      ..write(obj.name)
      ..writeByte(9)
      ..write(obj.pos);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TeamDataModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
