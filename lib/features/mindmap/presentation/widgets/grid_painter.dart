import 'package:flutter/material.dart';

class GridPainter extends CustomPainter {
  final ColorScheme colorScheme;
  final double scale;
  final Offset offset;

  GridPainter({
    required this.colorScheme,
    required this.scale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.2)
      ..strokeWidth = 1.0;

    const gridSize = 40.0;
    
    // Transform canvas carefully to avoid infinite drawing
    // We just want a simple grid background that covers the screen
    // independent of zoom/pan for simplicity, OR we can make it move with content.
    // If we make it move, it might be disorienting if not infinite.
    // For "Simple Mode", a static grid or dot pattern is often best.
    
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(GridPainter oldDelegate) => false;
}
