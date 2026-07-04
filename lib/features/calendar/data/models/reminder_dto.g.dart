// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder_dto.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ReminderDtoAdapter extends TypeAdapter<ReminderDto> {
  @override
  final int typeId = 3;

  @override
  ReminderDto read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ReminderDto(
      id: fields[0] as String,
      title: fields[1] as String,
      date: fields[2] as DateTime,
      importanceLevel: fields[3] as String,
      description: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ReminderDto obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.importanceLevel)
      ..writeByte(4)
      ..write(obj.description);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReminderDtoAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
