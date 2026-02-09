import 'dart:math' as math;

import 'package:flutter/material.dart';

class NotebookCover extends StatelessWidget {
  final Color color;
  final String texture; // 'leather', 'fabric', 'classic'
  final Widget? child;

  const NotebookCover({
    super.key,
    required this.color,
    required this.texture,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(4, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Texture Overlay
          Positioned.fill(child: _buildTexture()),
          // Binding Line
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            width: 2,
            child: Container(color: Colors.black.withValues(alpha: 0.1)),
          ),
          // Content
          if (child != null) Positioned.fill(child: child!),
        ],
      ),
    );
  }

  Widget _buildTexture() {
    switch (texture) {
      case 'leather':
        return CustomPaint(painter: _LeatherPainter(color: color));
      case 'fabric':
        return CustomPaint(painter: _FabricPainter(color: color));
      default:
        return const SizedBox.shrink();
    }
  }
}

class _LeatherPainter extends CustomPainter {
  final Color color;
  _LeatherPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.05)
          ..strokeWidth = 1.0;

    // Subtle noise/grain for leather
    final random = _NotebookRandom(42); // Seed for consistency
    for (int i = 0; i < 500; i++) {
      final x = (size.width * random.nextDouble());
      final y = (size.height * random.nextDouble());
      canvas.drawCircle(Offset(x, y), 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Local Random helper
class _NotebookRandom {
  final math.Random _r;
  _NotebookRandom(int seed) : _r = math.Random(seed);
  double nextDouble() => _r.nextDouble();
}

class _FabricPainter extends CustomPainter {
  final Color color;
  _FabricPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 0.5;

    // Cross-hatch for fabric
    for (double i = 0; i < size.width; i += 4) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 4) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
