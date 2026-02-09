import 'package:flutter/material.dart';

class PaperBackground extends StatelessWidget {
  final Widget? child;
  final bool showLines;
  final Color? lineColor;

  const PaperBackground({
    super.key,
    this.child,
    this.showLines = false,
    this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveLineColor = lineColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        image: const DecorationImage(
          image: AssetImage('assets/images/paper_texture.png'),
          fit: BoxFit.cover,
          opacity: 0.15, // Subtle texture overlay
        ),
      ),
      child: Stack(
        children: [
          if (showLines)
            Positioned.fill(
              child: CustomPaint(
                painter: _PaperLinesPainter(color: effectiveLineColor),
              ),
            ),
          if (child != null) child!,
        ],
      ),
    );
  }
}

class _PaperLinesPainter extends CustomPainter {
  final Color color;

  _PaperLinesPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;

    const double lineSpacing = 30.0;
    const double leftMargin = 50.0;

    // Build vertical margin line
    canvas.drawLine(
      const Offset(leftMargin, 0),
      Offset(leftMargin, size.height),
      Paint()
        ..color = color.withValues(alpha: 0.8)
        ..strokeWidth = 1.5,
    );

    // Draw horizontal lines
    for (double y = lineSpacing; y < size.height; y += lineSpacing) {
      canvas.drawLine(
        Offset(leftMargin, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
