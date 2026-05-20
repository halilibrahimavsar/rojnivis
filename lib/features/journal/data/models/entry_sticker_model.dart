import '../../domain/entities/entry_sticker.dart';

class EntryStickerModel extends EntrySticker {
  const EntryStickerModel({
    required super.id,
    required super.assetPath,
    required super.x,
    required super.y,
    super.scale = 1.0,
    super.rotation = 0.0,
    super.zIndex = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'assetPath': assetPath,
      'x': x,
      'y': y,
      'scale': scale,
      'rotation': rotation,
      'zIndex': zIndex,
    };
  }

  factory EntryStickerModel.fromJson(Map<String, dynamic> json) {
    return EntryStickerModel(
      id: json['id'] as String,
      assetPath: json['assetPath'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
    );
  }

  factory EntryStickerModel.fromEntity(EntrySticker entity) {
    return EntryStickerModel(
      id: entity.id,
      assetPath: entity.assetPath,
      x: entity.x,
      y: entity.y,
      scale: entity.scale,
      rotation: entity.rotation,
      zIndex: entity.zIndex,
    );
  }

  EntrySticker toEntity() {
    return EntrySticker(
      id: id,
      assetPath: assetPath,
      x: x,
      y: y,
      scale: scale,
      rotation: rotation,
      zIndex: zIndex,
    );
  }
}
