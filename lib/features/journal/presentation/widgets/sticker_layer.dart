import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/models/entry_sticker.dart';
import 'sticker_transform_handles.dart';

class StickerLayerController extends ChangeNotifier {
  StickerLayerController({List<EntrySticker>? stickers})
      : _stickers = List<EntrySticker>.from(stickers ?? const []);

  List<EntrySticker> _stickers;
  String? _selectedStickerId;

  List<EntrySticker> get stickers {
    final sorted = List<EntrySticker>.from(_stickers);
    sorted.sort((a, b) => a.zIndex.compareTo(b.zIndex));
    return sorted;
  }

  String? get selectedStickerId => _selectedStickerId;

  void setStickers(List<EntrySticker> stickers) {
    _stickers = List<EntrySticker>.from(stickers);
    _selectedStickerId = null;
    notifyListeners();
  }

  void addSticker(String assetPath) {
    final nextZ =
        _stickers.isEmpty ? 0 : _stickers.map((s) => s.zIndex).reduce(max) + 1;
    final id = 'stk_${DateTime.now().microsecondsSinceEpoch}_$nextZ';
    _stickers.add(
      EntrySticker(
        id: id,
        assetPath: assetPath,
        x: 0.5,
        y: 0.36,
        scale: 1.0,
        rotation: 0.0,
        zIndex: nextZ,
      ),
    );
    _selectedStickerId = id;
    notifyListeners();
  }

  void select(String? id) {
    _selectedStickerId = id;
    notifyListeners();
  }

  void bringToFront(String id) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    final topZ =
        _stickers.isEmpty ? 0 : _stickers.map((s) => s.zIndex).reduce(max);
    _stickers[index] = _stickers[index].copyWith(zIndex: topZ + 1);
    notifyListeners();
  }

  void updateTransform({
    required String id,
    required double x,
    required double y,
    required double scale,
    required double rotation,
  }) {
    final index = _stickers.indexWhere((s) => s.id == id);
    if (index == -1) return;
    _stickers[index] = _stickers[index].copyWith(
      x: x.clamp(0.05, 0.95),
      y: y.clamp(0.05, 0.95),
      scale: scale.clamp(0.35, 2.8),
      rotation: rotation,
    );
    notifyListeners();
  }

  void deleteSelected() {
    final selected = _selectedStickerId;
    if (selected == null) return;
    _stickers.removeWhere((s) => s.id == selected);
    _selectedStickerId = null;
    notifyListeners();
  }

  void clearSelection() {
    if (_selectedStickerId == null) return;
    _selectedStickerId = null;
    notifyListeners();
  }
}

class StickerLayer extends StatefulWidget {
  const StickerLayer({
    super.key,
    required this.controller,
    required this.editable,
    this.onChanged,
  });

  final StickerLayerController controller;
  final bool editable;
  final ValueChanged<List<EntrySticker>>? onChanged;

  @override
  State<StickerLayer> createState() => _StickerLayerState();
}

class _StickerLayerState extends State<StickerLayer> {
  String? _activeId;
  double _startScale = 1.0;
  double _startRotation = 0.0;
  String _lastStickerSignature = '';

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_notifyChanged);
  }

  @override
  void didUpdateWidget(covariant StickerLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_notifyChanged);
      widget.controller.addListener(_notifyChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_notifyChanged);
    super.dispose();
  }

  void _notifyChanged() {
    final stickers = widget.controller.stickers;
    final signature = stickers
        .map((s) => '${s.id}:${s.x}:${s.y}:${s.scale}:${s.rotation}:${s.zIndex}')
        .join('|');
    if (signature == _lastStickerSignature) return;
    _lastStickerSignature = signature;
    widget.onChanged?.call(stickers);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        return AnimatedBuilder(
          animation: widget.controller,
          builder: (context, _) {
            final stickers = widget.controller.stickers;
            return Stack(
              clipBehavior: Clip.none,
              children: [
                for (final sticker in stickers)
                  _buildStickerItem(context, sticker, size),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStickerItem(BuildContext context, EntrySticker sticker, Size area) {
    const baseSize = 82.0;
    final isSelected = sticker.id == widget.controller.selectedStickerId;
    final stickerSize = baseSize * sticker.scale;

    final left = (sticker.x * area.width) - (stickerSize / 2);
    final top = (sticker.y * area.height) - (stickerSize / 2);

    return Positioned(
      left: left,
      top: top,
      width: stickerSize,
      height: stickerSize,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.editable
            ? () {
                widget.controller.select(sticker.id);
                widget.controller.bringToFront(sticker.id);
              }
            : null,
        onScaleStart: !widget.editable
            ? null
            : (details) {
                _activeId = sticker.id;
                _startScale = sticker.scale;
                _startRotation = sticker.rotation;
                widget.controller.select(sticker.id);
                widget.controller.bringToFront(sticker.id);
              },
        onScaleUpdate: !widget.editable
            ? null
            : (details) {
                if (_activeId != sticker.id) return;
                final current = widget.controller.stickers.firstWhere(
                  (s) => s.id == sticker.id,
                  orElse: () => sticker,
                );
                final newX = current.x + (details.focalPointDelta.dx / area.width);
                final newY = current.y + (details.focalPointDelta.dy / area.height);
                widget.controller.updateTransform(
                  id: sticker.id,
                  x: newX,
                  y: newY,
                  scale: _startScale * details.scale,
                  rotation: _startRotation + details.rotation,
                );
              },
        onScaleEnd: !widget.editable
            ? null
            : (_) {
                _activeId = null;
              },
        child: Transform.rotate(
          angle: sticker.rotation,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildStickerAsset(sticker.assetPath)),
              if (widget.editable && isSelected)
                StickerTransformHandles(
                  onDelete: widget.controller.deleteSelected,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStickerAsset(String assetPath) {
    final lower = assetPath.toLowerCase();
    if (lower.endsWith('.svg')) {
      return SvgPicture.asset(assetPath, fit: BoxFit.contain);
    }
    return Image.asset(assetPath, fit: BoxFit.contain);
  }
}
