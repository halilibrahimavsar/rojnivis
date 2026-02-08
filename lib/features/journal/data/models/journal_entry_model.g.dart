// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_entry_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class JournalEntryModelAdapter extends TypeAdapter<JournalEntryModel> {
  @override
  final int typeId = 1;

  @override
  JournalEntryModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return JournalEntryModel(
      id: fields[0] as String,
      title: fields[1] as String,
      content: fields[2] as String,
      date: fields[3] as DateTime,
      moodIndex: fields[4] as int,
      tags: (fields[5] as List).cast<String>(),
      categoryId: fields[6] as String?,
      attachmentPaths: (fields[7] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, JournalEntryModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.moodIndex)
      ..writeByte(5)
      ..write(obj.tags)
      ..writeByte(6)
      ..write(obj.categoryId)
      ..writeByte(7)
      ..write(obj.attachmentPaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JournalEntryModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
