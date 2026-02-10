import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';

/// A minimap overview that shows the entire mind map graph and allows
/// drag-to-navigate by moving the viewport indicator.
class MindMapMinimap extends StatelessWidget {
  final MindMapNode root;
  final TransformationController transformController;
  final Size canvasSize;
  final Size viewportSize;

  const MindMapMinimap({
    super.key,
    required this.root,
    required this.transformController,
    this.canvasSize = const Size(10000, 10000),
    this.viewportSize = const Size(120, 80),
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      bottom: 16,
      right: 16,
      child: Container(
        width: viewportSize.width,
        height: viewportSize.height,
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: AnimatedBuilder(
          animation: transformController,
          builder: (context, child) {
            return CustomPaint(
              painter: _MinimapPainter(
                root: root,
                transform: transformController.value,
                viewportSize: viewportSize,
                canvasSize: canvasSize,
                colorScheme: colorScheme,
              ),
              size: viewportSize,
            );
          },
        ),
      ),
    );
  }
}

class _MinimapPainter extends CustomPainter {
  final MindMapNode root;
  final Matrix4 transform;
  final Size viewportSize;
  final Size canvasSize;
  final ColorScheme colorScheme;

  _MinimapPainter({
    required this.root,
    required this.transform,
    required this.viewportSize,
    required this.canvasSize,
    required this.colorScheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final nodes = _getAllNodes(root);
    if (nodes.isEmpty) return;

    // Find bounds of all nodes
    final bounds = _findBounds(nodes);
    if (bounds == Rect.zero) return;

    // Scale to fit minimap
    final padding = 10.0;
    final expandedBounds = Rect.fromLTRB(
      bounds.left - padding * 10,
      bounds.top - padding * 10,
      bounds.right + padding * 10,
      bounds.bottom + padding * 10,
    );

    final scaleX = (size.width - padding * 2) / expandedBounds.width;
    final scaleY = (size.height - padding * 2) / expandedBounds.height;
    final scale = math.min(scaleX, scaleY);

    final offsetX = padding - expandedBounds.left * scale +
        (size.width - padding * 2 - expandedBounds.width * scale) / 2;
    final offsetY = padding - expandedBounds.top * scale +
        (size.height - padding * 2 - expandedBounds.height * scale) / 2;

    // Draw connections
    _drawMinimapConnections(canvas, root, scale, offsetX, offsetY);

    // Draw nodes as dots
    for (final node in nodes) {
      final x = node.x * scale + offsetX;
      final y = node.y * scale + offsetY;

      canvas.drawCircle(
        Offset(x + 4, y + 3),
        3.0,
        Paint()
          ..color = node.color.withValues(alpha: 0.8)
          ..style = PaintingStyle.fill,
      );
    }

    // Draw viewport rectangle
    final inverted = Matrix4.tryInvert(transform);
    if (inverted != null) {
      final topLeft = MatrixUtils.transformPoint(inverted, Offset.zero);
      final bottomRight = MatrixUtils.transformPoint(
        inverted,
        Offset(viewportSize.width * 8, viewportSize.height * 8),
      );

      final viewRect = Rect.fromLTRB(
        topLeft.dx * scale + offsetX,
        topLeft.dy * scale + offsetY,
        bottomRight.dx * scale + offsetX,
        bottomRight.dy * scale + offsetY,
      );

      canvas.drawRect(
        viewRect,
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.3)
          ..style = PaintingStyle.fill,
      );
      canvas.drawRect(
        viewRect,
        Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.7)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke,
      );
    }
  }

  void _drawMinimapConnections(
    Canvas canvas,
    MindMapNode parent,
    double scale,
    double offsetX,
    double offsetY,
  ) {
    for (final child in parent.children) {
      canvas.drawLine(
        Offset(parent.x * scale + offsetX + 4, parent.y * scale + offsetY + 3),
        Offset(child.x * scale + offsetX + 4, child.y * scale + offsetY + 3),
        Paint()
          ..color = parent.color.withValues(alpha: 0.3)
          ..strokeWidth = 0.5,
      );
      _drawMinimapConnections(canvas, child, scale, offsetX, offsetY);
    }
  }

  List<MindMapNode> _getAllNodes(MindMapNode node) {
    final nodes = <MindMapNode>[node];
    for (final child in node.children) {
      nodes.addAll(_getAllNodes(child));
    }
    return nodes;
  }

  Rect _findBounds(List<MindMapNode> nodes) {
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final n in nodes) {
      minX = math.min(minX, n.x);
      minY = math.min(minY, n.y);
      maxX = math.max(maxX, n.x + 180);
      maxY = math.max(maxY, n.y + 60);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  @override
  bool shouldRepaint(_MinimapPainter oldDelegate) => true;
}
