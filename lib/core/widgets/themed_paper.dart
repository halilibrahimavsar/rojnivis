import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class ThemedPaper extends StatefulWidget {
  const ThemedPaper({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.lined = false,
    this.animated = true,
    this.minHeight,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final bool lined;
  final bool animated;
  final double? minHeight;

  @override
  State<ThemedPaper> createState() => _ThemedPaperState();
}

class ThemedBackdrop extends StatefulWidget {
  const ThemedBackdrop({
    super.key,
    this.animated = true,
    this.opacity = 0.9,
    this.blurSigma = 0,
    this.vignette = true,
  });

  final bool animated;
  final double opacity;
  final double blurSigma;
  final bool vignette;

  @override
  State<ThemedBackdrop> createState() => _ThemedBackdropState();
}

class _ThemedBackdropState extends State<ThemedBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ThemedBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<AppThemeStyle>();
    final preset = style?.preset ?? AppThemePreset.defaultPreset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _paperSpecFor(preset, isDark);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = widget.animated ? _controller.value : 0.0;
          final content = Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: spec.base,
                    gradient: _buildGradient(spec, t),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _PaperEffectPainter(spec: spec, progress: t),
                  ),
                ),
              ),
              if (widget.vignette)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.2),
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          (isDark ? Colors.black : Colors.black).withValues(
                            alpha: isDark ? 0.35 : 0.12,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );

          final layered =
              widget.blurSigma > 0
                  ? BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: widget.blurSigma,
                      sigmaY: widget.blurSigma,
                    ),
                    child: content,
                  )
                  : content;

          if (widget.opacity >= 0.999) return layered;
          return Opacity(opacity: widget.opacity, child: layered);
        },
      ),
    );
  }
}

class _ThemedPaperState extends State<ThemedPaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ThemedPaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animated != oldWidget.animated) {
      if (widget.animated) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<AppThemeStyle>();
    final preset = style?.preset ?? AppThemePreset.defaultPreset;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _paperSpecFor(preset, isDark);

    final shadowColor =
        isDark
            ? Colors.black.withValues(alpha: 0.45)
            : Colors.black.withValues(alpha: 0.12);

    Widget content = Padding(padding: widget.padding, child: widget.child);
    if (widget.minHeight != null) {
      content = ConstrainedBox(
        constraints: BoxConstraints(minHeight: widget.minHeight!),
        child: content,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: widget.borderRadius,
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius,
        child: AnimatedBuilder(
          animation: _controller,
          child: content,
          builder: (context, child) {
            final t = widget.animated ? _controller.value : 0.0;
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: spec.base,
                      gradient: _buildGradient(spec, t),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _PaperEffectPainter(spec: spec, progress: t),
                    ),
                  ),
                ),
                if (widget.lined)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _PaperLinesPainter(lineColor: spec.lineColor),
                    ),
                  ),
                child!,
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _PaperMotif { none, hearts, waves, petals, leaves, sun, grid, bubbles }

class _PaperSpec {
  const _PaperSpec({
    required this.base,
    required this.gradient,
    required this.accent,
    required this.accent2,
    required this.lineColor,
    required this.motif,
  });

  final Color base;
  final List<Color> gradient;
  final Color accent;
  final Color accent2;
  final Color lineColor;
  final _PaperMotif motif;
}

_PaperSpec _paperSpecFor(AppThemePreset preset, bool isDark) {
  switch (preset) {
    case AppThemePreset.love:
      return _PaperSpec(
        base: isDark ? const Color(0xFF2A131A) : const Color(0xFFFFF2F6),
        gradient:
            isDark
                ? const [Color(0xFF2A131A), Color(0xFF3B1B24)]
                : const [Color(0xFFFFF2F6), Color(0xFFFFD5E6)],
        accent: const Color(0xFFFF5C8D),
        accent2: const Color(0xFFFF9AA2),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.hearts,
      );
    case AppThemePreset.ocean:
      return _PaperSpec(
        base: isDark ? const Color(0xFF071826) : const Color(0xFFE7F6FF),
        gradient:
            isDark
                ? const [Color(0xFF071826), Color(0xFF0B2A3F)]
                : const [Color(0xFFE7F6FF), Color(0xFFB3E5FC)],
        accent: const Color(0xFF00C4FF),
        accent2: const Color(0xFF00F5D4),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.waves,
      );
    case AppThemePreset.sunset:
      return _PaperSpec(
        base: isDark ? const Color(0xFF24140E) : const Color(0xFFFFF4EA),
        gradient:
            isDark
                ? const [Color(0xFF24140E), Color(0xFF3A1B12)]
                : const [Color(0xFFFFF4EA), Color(0xFFFFD1B3)],
        accent: const Color(0xFFFF7A59),
        accent2: const Color(0xFF8B5CF6),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.sun,
      );
    case AppThemePreset.forest:
      return _PaperSpec(
        base: isDark ? const Color(0xFF0E1A12) : const Color(0xFFF3FAF4),
        gradient:
            isDark
                ? const [Color(0xFF0E1A12), Color(0xFF17301F)]
                : const [Color(0xFFF3FAF4), Color(0xFFDDEFD9)],
        accent: const Color(0xFF2E7D32),
        accent2: const Color(0xFF81C784),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.leaves,
      );
    case AppThemePreset.spring:
      return _PaperSpec(
        base: isDark ? const Color(0xFF102017) : const Color(0xFFF7FFF6),
        gradient:
            isDark
                ? const [Color(0xFF102017), Color(0xFF1A2C1D)]
                : const [Color(0xFFF7FFF6), Color(0xFFE8FEE8)],
        accent: const Color(0xFFFF8AD4),
        accent2: const Color(0xFF8EE4AF),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.petals,
      );
    case AppThemePreset.autumn:
      return _PaperSpec(
        base: isDark ? const Color(0xFF20140C) : const Color(0xFFFFF8F0),
        gradient:
            isDark
                ? const [Color(0xFF20140C), Color(0xFF2F1B10)]
                : const [Color(0xFFFFF8F0), Color(0xFFFFE1C1)],
        accent: const Color(0xFFC75D2C),
        accent2: const Color(0xFFFFB347),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.leaves,
      );
    case AppThemePreset.futuristic:
      return _PaperSpec(
        base: isDark ? const Color(0xFF0A0F1E) : const Color(0xFFF1F7FF),
        gradient:
            isDark
                ? const [Color(0xFF0A0F1E), Color(0xFF111A2D)]
                : const [Color(0xFFF1F7FF), Color(0xFFDDE9FF)],
        accent: const Color(0xFF00E5FF),
        accent2: const Color(0xFFB388FF),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.04),
        motif: _PaperMotif.grid,
      );
    case AppThemePreset.glass:
      return _PaperSpec(
        base: isDark ? const Color(0xFF0C172A) : const Color(0xFFF4F9FF),
        gradient:
            isDark
                ? const [Color(0xFF0C172A), Color(0xFF10233C)]
                : const [Color(0xFFF4F9FF), Color(0xFFE6F2FF)],
        accent: const Color(0xFF74B9FF),
        accent2: const Color(0xFF00CEC9),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.bubbles,
      );
    case AppThemePreset.neomorphic:
      return _PaperSpec(
        base: isDark ? const Color(0xFF171A1F) : const Color(0xFFF2F4F6),
        gradient:
            isDark
                ? const [Color(0xFF171A1F), Color(0xFF1E232A)]
                : const [Color(0xFFF2F4F6), Color(0xFFE1E6EA)],
        accent: const Color(0xFFB2BEC3),
        accent2: const Color(0xFF6C5CE7),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.none,
      );
    case AppThemePreset.defaultPreset:
      return _PaperSpec(
        base: isDark ? const Color(0xFF141326) : const Color(0xFFFCFBFF),
        gradient:
            isDark
                ? const [Color(0xFF141326), Color(0xFF1C1B34)]
                : const [Color(0xFFFCFBFF), Color(0xFFF3F1FF)],
        accent: const Color(0xFF6C5CE7),
        accent2: const Color(0xFF00CEC9),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.grid,
      );
  }
}

Gradient _buildGradient(_PaperSpec spec, double t) {
  final drift = sin(t * pi * 2) * 0.15;
  if (spec.motif == _PaperMotif.sun) {
    return RadialGradient(
      center: Alignment(0.7 + drift, -0.6),
      radius: 1.3,
      colors: spec.gradient,
    );
  }
  return LinearGradient(
    begin: Alignment(-0.9 + drift, -1.0),
    end: Alignment(0.9 - drift, 1.0),
    colors: spec.gradient,
  );
}

class _PaperEffectPainter extends CustomPainter {
  _PaperEffectPainter({required this.spec, required this.progress});

  final _PaperSpec spec;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    switch (spec.motif) {
      case _PaperMotif.hearts:
        _drawHearts(canvas, size);
        break;
      case _PaperMotif.waves:
        _drawWaves(canvas, size);
        break;
      case _PaperMotif.petals:
        _drawPetals(canvas, size);
        break;
      case _PaperMotif.leaves:
        _drawLeaves(canvas, size);
        break;
      case _PaperMotif.sun:
        _drawSun(canvas, size);
        break;
      case _PaperMotif.grid:
        _drawGrid(canvas, size);
        break;
      case _PaperMotif.bubbles:
        _drawBubbles(canvas, size);
        break;
      case _PaperMotif.none:
        break;
    }
  }

  void _drawHearts(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.fill;

    final random = Random(42);
    for (int i = 0; i < 14; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = lerpDouble(0.02, 0.08, random.nextDouble())!;
      final drift = random.nextDouble();
      final dy = (y - progress * speed + 1.2) % 1.2 - 0.1;
      final dx = x + sin((progress + drift) * pi * 2) * 0.02;
      final sizeFactor = lerpDouble(10, 24, random.nextDouble())!;
      _paintHeart(
        canvas,
        Offset(dx * size.width, dy * size.height),
        sizeFactor,
        paint,
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.18)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      final y = size.height * (0.35 + i * 0.2);
      final amplitude = 8 + i * 4;
      final frequency = 2.2 + i * 0.4;
      final phase = progress * pi * 2 * (0.6 + i * 0.2);
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 16) {
        final dy = sin((x / size.width) * pi * frequency + phase) * amplitude;
        path.lineTo(x, y + dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawPetals(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.14)
          ..style = PaintingStyle.fill;

    final random = Random(7);
    for (int i = 0; i < 16; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = lerpDouble(0.02, 0.06, random.nextDouble())!;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final sizeFactor = lerpDouble(10, 20, random.nextDouble())!;
      final angle = progress * pi * 2 * (0.4 + random.nextDouble());
      _paintPetal(
        canvas,
        Offset(x * size.width, dy * size.height),
        sizeFactor,
        angle,
        paint,
      );
    }
  }

  void _drawLeaves(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent2.withValues(alpha: 0.16)
          ..style = PaintingStyle.fill;

    final random = Random(11);
    for (int i = 0; i < 12; i++) {
      final x = random.nextDouble();
      final y = random.nextDouble();
      final speed = lerpDouble(0.015, 0.05, random.nextDouble())!;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final sizeFactor = lerpDouble(12, 24, random.nextDouble())!;
      final angle = progress * pi * 2 * (0.3 + random.nextDouble());
      _paintLeaf(
        canvas,
        Offset(x * size.width, dy * size.height),
        sizeFactor,
        angle,
        paint,
      );
    }
  }

  void _drawSun(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.82, size.height * 0.18);
    final radius = size.shortestSide * 0.22;
    final glowPaint =
        Paint()
          ..shader = RadialGradient(
            colors: [spec.accent.withValues(alpha: 0.35), Colors.transparent],
          ).createShader(Rect.fromCircle(center: center, radius: radius * 1.6));
    canvas.drawCircle(center, radius * 1.4, glowPaint);

    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.18)
          ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.7, paint);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.08)
          ..strokeWidth = 1;

    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawBubbles(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;

    final random = Random(21);
    for (int i = 0; i < 10; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          ((random.nextDouble() + progress) % 1.1) * size.height -
          size.height * 0.05;
      final radius = lerpDouble(18, 40, random.nextDouble())!;
      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  void _paintHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final width = size;
    final height = size;
    path.moveTo(center.dx, center.dy + height * 0.35);
    path.cubicTo(
      center.dx + width * 0.5,
      center.dy - height * 0.2,
      center.dx + width * 1.1,
      center.dy + height * 0.25,
      center.dx,
      center.dy + height,
    );
    path.cubicTo(
      center.dx - width * 1.1,
      center.dy + height * 0.25,
      center.dx - width * 0.5,
      center.dy - height * 0.2,
      center.dx,
      center.dy + height * 0.35,
    );
    canvas.drawPath(path, paint);
  }

  void _paintPetal(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size * 1.2,
      height: size * 0.55,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawOval(rect, paint);
    canvas.restore();
  }

  void _paintLeaf(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Paint paint,
  ) {
    final path = Path();
    path.moveTo(0, 0);
    path.quadraticBezierTo(size * 0.6, -size, size * 1.1, 0);
    path.quadraticBezierTo(size * 0.5, size, 0, 0);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    canvas.drawPath(path, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PaperEffectPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.spec != spec;
  }
}

class _PaperLinesPainter extends CustomPainter {
  _PaperLinesPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1;

    const topPadding = 64.0;
    const lineStep = 28.0;
    for (double y = topPadding; y < size.height; y += lineStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final marginPaint =
        Paint()
          ..color = lineColor.withValues(
            alpha: (lineColor.a * 1.6).clamp(0.0, 1.0),
          )
          ..strokeWidth = 1;
    canvas.drawLine(const Offset(48, 0), Offset(48, size.height), marginPaint);
  }

  @override
  bool shouldRepaint(covariant _PaperLinesPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}
