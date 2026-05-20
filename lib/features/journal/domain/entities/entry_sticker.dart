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
}
