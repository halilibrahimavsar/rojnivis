class EntrySticker {
  const EntrySticker({
    required this.id,
    required this.assetPath,
    required this.x,
    required this.y,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.zIndex = 0,
  });

  final String id;
  final String assetPath;
  final double x;
  final double y;
  final double scale;
  final double rotation;
  final int zIndex;

  EntrySticker copyWith({
    String? id,
    String? assetPath,
    double? x,
    double? y,
    double? scale,
    double? rotation,
    int? zIndex,
  }) {
    return EntrySticker(
      id: id ?? this.id,
      assetPath: assetPath ?? this.assetPath,
      x: x ?? this.x,
      y: y ?? this.y,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
    );
  }

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

  static EntrySticker fromJson(Map<String, dynamic> json) {
    return EntrySticker(
      id: json['id'] as String,
      assetPath: json['assetPath'] as String,
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['zIndex'] as num?)?.toInt() ?? 0,
    );
  }
}
