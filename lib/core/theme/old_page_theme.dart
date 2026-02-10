import 'dart:math' as math;
import 'package:flutter/material.dart';

// ─────────────────────────────────────────────────────────────────
// 1. OldPageColors — ThemeExtension with paper/ink tones
// ─────────────────────────────────────────────────────────────────

/// Theme extension providing aged-paper color tokens.
///
/// Access via `Theme.of(context).extension<OldPageColors>()`.
@immutable
class OldPageColors extends ThemeExtension<OldPageColors> {
  /// Paper background (warm cream / dark sepia).
  final Color paper;

  /// Darker ink color for text on paper.
  final Color ink;

  /// Subtle stain spots (coffee / age marks).
  final Color stain;

  /// Margin line color.
  final Color marginLine;

  /// Edge shadow / vignette tint.
  final Color edgeShadow;

  /// Ruled-line color (faint).
  final Color ruledLine;

  const OldPageColors({
    required this.paper,
    required this.ink,
    required this.stain,
    required this.marginLine,
    required this.edgeShadow,
    required this.ruledLine,
  });

  /// Light-mode old page palette.
  static const light = OldPageColors(
    paper: Color(0xFFF5F0E1),       // warm parchment
    ink: Color(0xFF2C2416),          // dark sepia ink
    stain: Color(0x18A0845C),        // faint coffee stain
    marginLine: Color(0x22C96B4F),   // faded red margin
    edgeShadow: Color(0x1A3E2C1A),   // dark vignette edge
    ruledLine: Color(0x0E6B8EAF),    // faint blue ruled
  );

  /// Dark-mode old page palette (midnight parchment).
  static const dark = OldPageColors(
    paper: Color(0xFF1E1A14),        // dark aged paper
    ink: Color(0xFFD4C9A8),          // light sepia ink
    stain: Color(0x12A0845C),        // subtle stain
    marginLine: Color(0x18C96B4F),   // dim margin
    edgeShadow: Color(0x20000000),   // deep shadow
    ruledLine: Color(0x0A6B8EAF),    // dim ruled line
  );

  @override
  OldPageColors copyWith({
    Color? paper,
    Color? ink,
    Color? stain,
    Color? marginLine,
    Color? edgeShadow,
    Color? ruledLine,
  }) {
    return OldPageColors(
      paper: paper ?? this.paper,
      ink: ink ?? this.ink,
      stain: stain ?? this.stain,
      marginLine: marginLine ?? this.marginLine,
      edgeShadow: edgeShadow ?? this.edgeShadow,
      ruledLine: ruledLine ?? this.ruledLine,
    );
  }

  @override
  ThemeExtension<OldPageColors> lerp(
    covariant ThemeExtension<OldPageColors>? other,
    double t,
  ) {
    if (other is! OldPageColors) return this;
    return OldPageColors(
      paper: Color.lerp(paper, other.paper, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      stain: Color.lerp(stain, other.stain, t)!,
      marginLine: Color.lerp(marginLine, other.marginLine, t)!,
      edgeShadow: Color.lerp(edgeShadow, other.edgeShadow, t)!,
      ruledLine: Color.lerp(ruledLine, other.ruledLine, t)!,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 2. OldPageBackground — Full-screen aged paper texture
// ─────────────────────────────────────────────────────────────────

/// Renders an aged paper background with grain, stains, and edge darkening.
///
/// Use as the bottom layer of a Stack wrapping your page content:
/// ```dart
/// Stack(children: [
///   const OldPageBackground(),
///   // ... your content
/// ])
/// ```
class OldPageBackground extends StatelessWidget {
  /// Whether to show faint ruled lines.
  final bool showRuledLines;

  /// Whether to show margin line.
  final bool showMarginLine;

  /// Whether to draw age stain spots.
  final bool showStains;

  const OldPageBackground({
    super.key,
    this.showRuledLines = false,
    this.showMarginLine = false,
    this.showStains = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<OldPageColors>() ?? OldPageColors.light;

    return SizedBox.expand(
      child: CustomPaint(
        painter: _OldPagePainter(
          colors: colors,
          showRuledLines: showRuledLines,
          showMarginLine: showMarginLine,
          showStains: showStains,
        ),
      ),
    );
  }
}

class _OldPagePainter extends CustomPainter {
  final OldPageColors colors;
  final bool showRuledLines;
  final bool showMarginLine;
  final bool showStains;

  _OldPagePainter({
    required this.colors,
    required this.showRuledLines,
    required this.showMarginLine,
    required this.showStains,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Base paper fill
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = colors.paper,
    );

    // 2. Paper grain noise (deterministic dots)
    _drawGrain(canvas, size);

    // 3. Edge vignette (darkened edges)
    _drawVignette(canvas, size);

    // 4. Age stain spots
    if (showStains) _drawStains(canvas, size);

    // 5. Ruled lines
    if (showRuledLines) _drawRuledLines(canvas, size);

    // 6. Margin line
    if (showMarginLine) _drawMarginLine(canvas, size);
  }

  void _drawGrain(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final random = math.Random(42);
    final grainCount = (size.width * size.height / 800).clamp(100, 3000).toInt();

    for (var i = 0; i < grainCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final alpha = random.nextDouble() * 0.04;
      final radius = 0.3 + random.nextDouble() * 0.8;

      paint.color = (random.nextBool() ? Colors.black : Colors.white)
          .withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawVignette(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.85,
        colors: [
          Colors.transparent,
          colors.edgeShadow,
        ],
        stops: const [0.6, 1.0],
      ).createShader(rect);

    canvas.drawRect(rect, paint);
  }

  void _drawStains(Canvas canvas, Size size) {
    final random = math.Random(17);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);

    // 3-5 subtle stain spots
    for (var i = 0; i < 4; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = 20 + random.nextDouble() * 60;

      paint.color = colors.stain;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _drawRuledLines(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.ruledLine
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 28.0;
    double y = spacing * 3; // start below top margin
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing;
    }
  }

  void _drawMarginLine(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = colors.marginLine
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(44, 0),
      Offset(44, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_OldPagePainter oldDelegate) =>
      colors != oldDelegate.colors ||
      showRuledLines != oldDelegate.showRuledLines;
}

// ─────────────────────────────────────────────────────────────────
// 3. AgedPaperDecoration — Card/container decoration factory
// ─────────────────────────────────────────────────────────────────

/// Creates a BoxDecoration that makes any container look like aged paper.
class AgedPaperDecoration {
  /// Standard card decoration with parchment feel.
  static BoxDecoration card(BuildContext context, {double radius = 16}) {
    final colors =
        Theme.of(context).extension<OldPageColors>() ?? OldPageColors.light;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: colors.paper.withValues(alpha: 0.92),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colors.ink.withValues(alpha: isDark ? 0.08 : 0.06),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: colors.edgeShadow.withValues(alpha: 0.08),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
        // Inner warm glow
        BoxShadow(
          color: colors.stain.withValues(alpha: 0.04),
          blurRadius: 20,
          spreadRadius: -4,
        ),
      ],
    );
  }

  /// Flat paper surface (no elevation), for areas that should feel inset.
  static BoxDecoration flat(BuildContext context, {double radius = 12}) {
    final colors =
        Theme.of(context).extension<OldPageColors>() ?? OldPageColors.light;

    return BoxDecoration(
      color: colors.paper.withValues(alpha: 0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: colors.ink.withValues(alpha: 0.04),
        width: 0.5,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 4. PageEdgeEffect — Torn/deckled edge for panels
// ─────────────────────────────────────────────────────────────────

/// Adds a subtle deckled (torn) edge effect to the bottom of a widget.
class PageEdgeEffect extends StatelessWidget {
  final Widget child;

  const PageEdgeEffect({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<OldPageColors>() ?? OldPageColors.light;

    return Stack(
      children: [
        child,
        // Bottom deckled edge shadow
        Positioned(
          bottom: -1,
          left: 0,
          right: 0,
          height: 6,
          child: CustomPaint(
            painter: _DeckledEdgePainter(color: colors.edgeShadow),
          ),
        ),
      ],
    );
  }
}

class _DeckledEdgePainter extends CustomPainter {
  final Color color;
  _DeckledEdgePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(99);
    final path = Path()..moveTo(0, 0);

    // Jagged deckled profile
    double x = 0;
    while (x < size.width) {
      final jag = random.nextDouble() * 3;
      path.lineTo(x, jag);
      x += 3 + random.nextDouble() * 4;
    }
    path.lineTo(size.width, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(_DeckledEdgePainter oldDelegate) =>
      color != oldDelegate.color;
}

// ─────────────────────────────────────────────────────────────────
// 5. WaxSealBadge — Decorative category badge
// ─────────────────────────────────────────────────────────────────

/// A decorative wax-seal shaped badge for categories and labels.
class WaxSealBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double size;

  const WaxSealBadge({
    super.key,
    required this.label,
    this.color = const Color(0xFFC0392B),
    this.size = 48,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _WaxSealPainter(color: color),
        child: Center(
          child: Text(
            label.isNotEmpty ? label[0].toUpperCase() : '',
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.38,
              fontWeight: FontWeight.w900,
              fontFamily: 'Caveat',
            ),
          ),
        ),
      ),
    );
  }
}

class _WaxSealPainter extends CustomPainter {
  final Color color;
  _WaxSealPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final random = math.Random(7);

    // Irregular circle for wax seal effect
    final path = Path();
    for (var i = 0; i < 36; i++) {
      final angle = (i / 36) * 2 * math.pi;
      final jitter = radius * (0.9 + random.nextDouble() * 0.15);
      final x = center.dx + math.cos(angle) * jitter;
      final y = center.dy + math.sin(angle) * jitter;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Shadow
    canvas.drawPath(
      path.shift(const Offset(1, 2)),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Main seal
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );

    // Highlight
    canvas.drawCircle(
      Offset(center.dx - radius * 0.2, center.dy - radius * 0.2),
      radius * 0.25,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );
  }

  @override
  bool shouldRepaint(_WaxSealPainter oldDelegate) =>
      color != oldDelegate.color;
}
