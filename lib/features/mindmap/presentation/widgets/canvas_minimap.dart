import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'canvas_controller.dart';
import '../../domain/models/mind_map_node.dart';

/// Professional minimap for canvas navigation
class CanvasMinimap extends StatelessWidget {
  const CanvasMinimap({
    super.key,
    required this.controller,
    required this.viewportSize,
    this.width = 200.0,
    this.height = 150.0,
  });

  final CanvasController controller;
  final Size viewportSize;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            final minimapSize = Size(width, height);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown:
                  (details) => _navigateTo(details.localPosition, minimapSize),
              onPanStart:
                  (details) => _navigateTo(details.localPosition, minimapSize),
              onPanUpdate:
                  (details) => _navigateTo(details.localPosition, minimapSize),
              child: CustomPaint(
                painter: _MinimapPainter(
                  controller: controller,
                  colorScheme: colorScheme,
                  viewportSize: viewportSize,
                ),
                size: minimapSize,
              ),
            );
          },
        ),
      ),
    );
  }

  void _navigateTo(Offset localPosition, Size minimapSize) {
    if (viewportSize.isEmpty) return;

    final nodes = controller.getAllNodes();
    final transform = _MinimapTransform.compute(nodes, minimapSize);
    if (transform == null || transform.scale == 0) return;

    final worldPoint = Offset(
      (localPosition.dx - transform.offsetX) / transform.scale,
      (localPosition.dy - transform.offsetY) / transform.scale,
    );

    controller.centerOnPoint(worldPoint, viewportSize: viewportSize);
  }
}

class _MinimapPainter extends CustomPainter {
  _MinimapPainter({
    required this.controller,
    required this.colorScheme,
    required this.viewportSize,
  });

  final CanvasController controller;
  final ColorScheme colorScheme;
  final Size viewportSize;

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = controller.getAllNodes();
    if (nodes.isEmpty) return;

    final transform = _MinimapTransform.compute(nodes, size);
    if (transform == null) return;

    final scale = transform.scale;
    final offsetX = transform.offsetX;
    final offsetY = transform.offsetY;

    // Draw background
    final bgPaint =
        Paint()
          ..color = colorScheme.surfaceContainerHighest.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill;
    canvas.drawRect(Offset.zero & size, bgPaint);

    // Draw connections
    _drawConnections(canvas, nodes, scale, offsetX, offsetY);

    // Draw nodes
    _drawNodes(canvas, nodes, scale, offsetX, offsetY);

    // Draw viewport indicator
    _drawViewport(canvas, size, scale, offsetX, offsetY);
  }

  void _drawConnections(
    Canvas canvas,
    List<MindMapNode> nodes,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    final paint =
        Paint()
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

    void drawConnection(MindMapNode parent, MindMapNode child) {
      paint.color = parent.color.withValues(alpha: 0.4);

      final start = Offset(
        (parent.x + 180) * scale + offsetX,
        (parent.y + 30) * scale + offsetY,
      );

      final end = Offset(
        child.x * scale + offsetX,
        (child.y + 30) * scale + offsetY,
      );

      canvas.drawLine(start, end, paint);
    }

    void traverse(MindMapNode node) {
      for (final child in node.children) {
        drawConnection(node, child);
        traverse(child);
      }
    }

    traverse(controller.currentMindMap);
  }

  void _drawNodes(
    Canvas canvas,
    List<MindMapNode> nodes,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    for (final node in nodes) {
      final x = node.x * scale + offsetX;
      final y = node.y * scale + offsetY;
      final w = 180 * scale;
      final h = 60 * scale;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        Radius.circular(2.0),
      );

      // Node background
      final bgPaint =
          Paint()
            ..color = node.color.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill;

      canvas.drawRRect(rect, bgPaint);

      // Node border
      final borderPaint =
          Paint()
            ..color = node.color
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

      canvas.drawRRect(rect, borderPaint);
    }
  }

  void _drawViewport(
    Canvas canvas,
    Size size,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    if (viewportSize.isEmpty) return;

    final viewportPaint =
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.2)
          ..style = PaintingStyle.fill;

    final viewportBorderPaint =
        Paint()
          ..color = colorScheme.primary
          ..strokeWidth = 2.0
          ..style = PaintingStyle.stroke;

    final topLeft = controller.screenToWorld(Offset.zero);
    final bottomRight = controller.screenToWorld(
      Offset(viewportSize.width, viewportSize.height),
    );

    final viewRect = Rect.fromPoints(
      Offset(topLeft.dx * scale + offsetX, topLeft.dy * scale + offsetY),
      Offset(
        bottomRight.dx * scale + offsetX,
        bottomRight.dy * scale + offsetY,
      ),
    );

    final viewportRect = RRect.fromRectAndRadius(
      viewRect,
      const Radius.circular(4),
    );

    canvas.drawRRect(viewportRect, viewportPaint);
    canvas.drawRRect(viewportRect, viewportBorderPaint);
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) {
    return oldDelegate.controller != controller ||
        oldDelegate.viewportSize != viewportSize;
  }
}

class _MinimapTransform {
  const _MinimapTransform({
    required this.bounds,
    required this.scale,
    required this.offsetX,
    required this.offsetY,
  });

  final Rect bounds;
  final double scale;
  final double offsetX;
  final double offsetY;

  static _MinimapTransform? compute(List<MindMapNode> nodes, Size size) {
    if (nodes.isEmpty) return null;

    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = math.min(minX, node.x);
      maxX = math.max(maxX, node.x + 180);
      minY = math.min(minY, node.y);
      maxY = math.max(maxY, node.y + 60);
    }

    final bounds = Rect.fromLTRB(minX, minY, maxX, maxY);
    if (bounds.width == 0 || bounds.height == 0) return null;

    final scaleX = size.width / bounds.width;
    final scaleY = size.height / bounds.height;
    final scale = math.min(scaleX, scaleY) * 0.9;

    final offsetX =
        (size.width - bounds.width * scale) / 2 - bounds.left * scale;
    final offsetY =
        (size.height - bounds.height * scale) / 2 - bounds.top * scale;

    return _MinimapTransform(
      bounds: bounds,
      scale: scale,
      offsetX: offsetX,
      offsetY: offsetY,
    );
  }
}
