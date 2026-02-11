import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';
import 'canvas_controller.dart';

/// Professional canvas renderer with optimized rendering pipeline
class CanvasRenderer extends CustomPainter {
  CanvasRenderer({
    required this.controller,
    required this.colorScheme,
    this.selectedNodeId,
    this.multiSelectedNodeIds = const {},
    this.showGrid = true,
    this.gridSize = 20.0,
  }) : super(repaint: controller);

  final CanvasController controller;
  final ColorScheme colorScheme;
  final String? selectedNodeId;
  final Set<String> multiSelectedNodeIds;
  final bool showGrid;
  final double gridSize;

  static const double _nodeWidth = 180.0;
  static const double _nodeHeight = 60.0;
  static const double _nodeRadius = 12.0;
  static const double _connectionStrokeWidth = 2.5;
  static const double _shadowBlur = 8.0;

  @override
  void paint(Canvas canvas, Size size) {
    // Save canvas state
    canvas.save();

    // Apply transform
    canvas.translate(controller.offset.dx, controller.offset.dy);
    canvas.scale(controller.zoom);

    // Calculate visible bounds for culling
    final visibleBounds = _calculateVisibleBounds(size);

    // Render layers
    if (showGrid) {
      _renderGrid(canvas, size, visibleBounds);
    }

    _renderConnections(canvas, visibleBounds);
    _renderNodes(canvas, visibleBounds);

    // Restore canvas state
    canvas.restore();
  }

  Rect _calculateVisibleBounds(Size size) {
    final topLeft = controller.screenToWorld(Offset.zero);
    final bottomRight = controller.screenToWorld(
      Offset(size.width, size.height),
    );
    return Rect.fromPoints(topLeft, bottomRight);
  }

  void _renderGrid(Canvas canvas, Size size, Rect visibleBounds) {
    final gridPaint =
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
          ..strokeWidth = 1.0 / controller.zoom
          ..style = PaintingStyle.stroke;

    final majorGridPaint =
        Paint()
          ..color = colorScheme.outlineVariant.withValues(alpha: 0.5)
          ..strokeWidth = 1.5 / controller.zoom
          ..style = PaintingStyle.stroke;

    final adjustedGridSize = gridSize;
    final majorGridSize = adjustedGridSize * 5;

    // Calculate grid bounds with padding
    final padding = adjustedGridSize * 10;
    final startX =
        ((visibleBounds.left - padding) / adjustedGridSize).floor() *
        adjustedGridSize;
    final endX =
        ((visibleBounds.right + padding) / adjustedGridSize).ceil() *
        adjustedGridSize;
    final startY =
        ((visibleBounds.top - padding) / adjustedGridSize).floor() *
        adjustedGridSize;
    final endY =
        ((visibleBounds.bottom + padding) / adjustedGridSize).ceil() *
        adjustedGridSize;

    // Vertical lines
    for (double x = startX; x <= endX; x += adjustedGridSize) {
      final isMajor = (x / majorGridSize).round() * majorGridSize == x;
      canvas.drawLine(
        Offset(x, startY),
        Offset(x, endY),
        isMajor ? majorGridPaint : gridPaint,
      );
    }

    // Horizontal lines
    for (double y = startY; y <= endY; y += adjustedGridSize) {
      final isMajor = (y / majorGridSize).round() * majorGridSize == y;
      canvas.drawLine(
        Offset(startX, y),
        Offset(endX, y),
        isMajor ? majorGridPaint : gridPaint,
      );
    }

    // Origin indicator
    final originPaint =
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.5)
          ..strokeWidth = 2.0 / controller.zoom
          ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset.zero, 5.0 / controller.zoom, originPaint);
  }

  void _renderConnections(Canvas canvas, Rect visibleBounds) {
    final connectionPaint =
        Paint()
          ..strokeWidth = _connectionStrokeWidth / controller.zoom
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round;

    void drawConnection(MindMapNode parent, MindMapNode child) {
      // Culling - skip if both nodes are outside visible bounds
      final parentRect = Rect.fromLTWH(
        parent.x,
        parent.y,
        _nodeWidth,
        _nodeHeight,
      );
      final childRect = Rect.fromLTWH(
        child.x,
        child.y,
        _nodeWidth,
        _nodeHeight,
      );
      if (!visibleBounds.overlaps(parentRect) &&
          !visibleBounds.overlaps(childRect)) {
        return;
      }

      final start = Offset(parent.x + _nodeWidth, parent.y + _nodeHeight / 2);
      final end = Offset(child.x, child.y + _nodeHeight / 2);

      // Bezier curve for smooth connections
      final controlPoint1 = Offset(
        start.dx + (end.dx - start.dx) * 0.5,
        start.dy,
      );
      final controlPoint2 = Offset(
        start.dx + (end.dx - start.dx) * 0.5,
        end.dy,
      );

      final path =
          Path()
            ..moveTo(start.dx, start.dy)
            ..cubicTo(
              controlPoint1.dx,
              controlPoint1.dy,
              controlPoint2.dx,
              controlPoint2.dy,
              end.dx,
              end.dy,
            );

      // Gradient color from parent to child
      connectionPaint.color = parent.color.withValues(alpha: 0.6);
      canvas.drawPath(path, connectionPaint);

      // Arrow head
      _drawArrowHead(canvas, controlPoint2, end, child.color);
    }

    void traverseAndDraw(MindMapNode node) {
      for (final child in node.children) {
        drawConnection(node, child);
        traverseAndDraw(child);
      }
    }

    traverseAndDraw(controller.currentMindMap);
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Color color) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    final direction = (to - from).direction;
    final arrowSize = 8.0 / controller.zoom;

    final path =
        Path()
          ..moveTo(to.dx, to.dy)
          ..lineTo(
            to.dx - arrowSize * math.cos(direction - math.pi / 6),
            to.dy - arrowSize * math.sin(direction - math.pi / 6),
          )
          ..lineTo(
            to.dx - arrowSize * math.cos(direction + math.pi / 6),
            to.dy - arrowSize * math.sin(direction + math.pi / 6),
          )
          ..close();

    canvas.drawPath(path, paint);
  }

  void _renderNodes(Canvas canvas, Rect visibleBounds) {
    final nodes = controller.getAllNodes();

    for (final node in nodes) {
      final nodeRect = Rect.fromLTWH(node.x, node.y, _nodeWidth, _nodeHeight);

      // Culling
      if (!visibleBounds.overlaps(nodeRect)) continue;

      final isSelected = node.id == selectedNodeId;
      final isMultiSelected = multiSelectedNodeIds.contains(node.id);
      final isRoot = node.id == controller.currentMindMap.id;

      _drawNode(canvas, node, isSelected || isMultiSelected, isRoot);
    }
  }

  void _drawNode(
    Canvas canvas,
    MindMapNode node,
    bool isSelected,
    bool isRoot,
  ) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(node.x, node.y, _nodeWidth, _nodeHeight),
      Radius.circular(_nodeRadius / controller.zoom),
    );

    // Shadow
    if (!isRoot) {
      final shadowPaint =
          Paint()
            ..color = Colors.black.withValues(alpha: 0.15)
            ..maskFilter = MaskFilter.blur(
              BlurStyle.normal,
              _shadowBlur / controller.zoom,
            );

      canvas.drawRRect(rect.shift(Offset(0, 3 / controller.zoom)), shadowPaint);
    }

    // Node background
    final bgColor = isRoot ? colorScheme.primaryContainer : colorScheme.surface;
    final nodePaint =
        Paint()
          ..color = bgColor
          ..style = PaintingStyle.fill;

    canvas.drawRRect(rect, nodePaint);

    // Node border
    final borderPaint =
        Paint()
          ..color =
              isSelected
                  ? colorScheme.primary
                  : node.color.withValues(alpha: 0.5)
          ..strokeWidth = (isSelected ? 3.0 : 1.5) / controller.zoom
          ..style = PaintingStyle.stroke;

    canvas.drawRRect(rect, borderPaint);

    // Selection highlight
    if (isSelected) {
      final selectionPaint =
          Paint()
            ..color = colorScheme.primary.withValues(alpha: 0.1)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, selectionPaint);
    }

    // Color indicator
    final colorIndicatorRect = Rect.fromLTWH(
      node.x + 12 / controller.zoom,
      node.y + _nodeHeight / 2 - 6 / controller.zoom,
      12 / controller.zoom,
      12 / controller.zoom,
    );

    final colorPaint =
        Paint()
          ..color = node.color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      colorIndicatorRect.center,
      6 / controller.zoom,
      colorPaint,
    );

    // Text
    _drawNodeText(canvas, node, rect);

    // Child count indicator
    if (node.children.isNotEmpty) {
      _drawChildCountIndicator(canvas, node, rect);
    }
  }

  void _drawNodeText(Canvas canvas, MindMapNode node, RRect rect) {
    final textSpan = TextSpan(
      text: node.label,
      style: TextStyle(
        color: colorScheme.onSurface,
        fontSize: 14 / controller.zoom,
        fontWeight: FontWeight.w600,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );

    final maxWidth = _nodeWidth - 40 / controller.zoom;
    textPainter.layout(maxWidth: maxWidth);

    final textOffset = Offset(
      rect.left + 30 / controller.zoom,
      rect.top + (_nodeHeight - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  void _drawChildCountIndicator(Canvas canvas, MindMapNode node, RRect rect) {
    final count = node.children.length;
    final badgeSize = 20.0 / controller.zoom;
    final badgeOffset = Offset(
      rect.right - badgeSize - 8 / controller.zoom,
      rect.top + 8 / controller.zoom,
    );

    // Badge background
    final badgePaint =
        Paint()
          ..color = node.color
          ..style = PaintingStyle.fill;

    canvas.drawCircle(
      badgeOffset + Offset(badgeSize / 2, badgeSize / 2),
      badgeSize / 2,
      badgePaint,
    );

    // Badge text
    final textSpan = TextSpan(
      text: count.toString(),
      style: TextStyle(
        color: Colors.white,
        fontSize: 11 / controller.zoom,
        fontWeight: FontWeight.bold,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();

    final textOffset = Offset(
      badgeOffset.dx + (badgeSize - textPainter.width) / 2,
      badgeOffset.dy + (badgeSize - textPainter.height) / 2,
    );

    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(CanvasRenderer oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.selectedNodeId != selectedNodeId ||
        oldDelegate.multiSelectedNodeIds != multiSelectedNodeIds ||
        oldDelegate.showGrid != showGrid ||
        oldDelegate.gridSize != gridSize;
  }
}
