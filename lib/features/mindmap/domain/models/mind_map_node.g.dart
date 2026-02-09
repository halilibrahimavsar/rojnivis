// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mind_map_node.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MindMapNodeAdapter extends TypeAdapter<MindMapNode> {
  @override
  final int typeId = 2;

  @override
  MindMapNode read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MindMapNode(
      id: fields[0] as String,
      label: fields[1] as String,
      children: (fields[2] as List).cast<MindMapNode>(),
      x: fields[3] as double,
      y: fields[4] as double,
      colorValue: fields[5] as int,
    );
  }

  @override
  void write(BinaryWriter writer, MindMapNode obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.children)
      ..writeByte(3)
      ..write(obj.x)
      ..writeByte(4)
      ..write(obj.y)
      ..writeByte(5)
      ..write(obj.colorValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MindMapNodeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
