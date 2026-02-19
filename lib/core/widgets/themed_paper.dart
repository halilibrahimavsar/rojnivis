import 'dart:math';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/page_studio_models.dart';

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
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant ThemedBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationState();
  }

  void _syncAnimationState() {
    final intensity =
        Theme.of(context).extension<AppThemeStyle>()?.animationIntensity ??
        AnimationIntensity.subtle;
    _controller.duration = switch (intensity) {
      AnimationIntensity.off => const Duration(seconds: 24),
      AnimationIntensity.subtle => const Duration(seconds: 26),
      AnimationIntensity.cinematic => const Duration(seconds: 12),
    };
    final shouldAnimate = widget.animated && intensity.isAnimated;
    if (shouldAnimate == _isRepeating) return;
    _isRepeating = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.0;
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
    final visualFamily = style?.pageVisualFamily ?? PageVisualFamily.classic;
    final variant =
        style?.vintagePaperVariant ?? VintagePaperVariant.parchment;
    final intensity = style?.animationIntensity ?? AnimationIntensity.subtle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _paperSpecFor(preset, isDark);
    final vintageSpec = _vintagePaperSpecFor(variant, isDark);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t = widget.animated && intensity.isAnimated
              ? _controller.value
              : 0.0;
          final content = Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color:
                        visualFamily == PageVisualFamily.vintage
                            ? vintageSpec.base
                            : spec.base,
                    gradient:
                        visualFamily == PageVisualFamily.vintage
                            ? _buildVintageGradient(vintageSpec, t, intensity)
                            : _buildGradient(spec, t),
                  ),
                ),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter:
                        visualFamily == PageVisualFamily.vintage
                            ? _VintageBackdropPainter(
                              spec: vintageSpec,
                              progress: t,
                              intensity: intensity,
                            )
                            : _PaperEffectPainter(spec: spec, progress: t),
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
  bool _isRepeating = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant ThemedPaper oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncAnimationState();
  }

  void _syncAnimationState() {
    final intensity =
        Theme.of(context).extension<AppThemeStyle>()?.animationIntensity ??
        AnimationIntensity.subtle;
    _controller.duration = switch (intensity) {
      AnimationIntensity.off => const Duration(seconds: 22),
      AnimationIntensity.subtle => const Duration(seconds: 22),
      AnimationIntensity.cinematic => const Duration(seconds: 10),
    };
    final shouldAnimate = widget.animated && intensity.isAnimated;
    if (shouldAnimate == _isRepeating) return;
    _isRepeating = shouldAnimate;
    if (shouldAnimate) {
      _controller.repeat();
    } else {
      _controller.stop();
      _controller.value = 0.0;
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
    final visualFamily = style?.pageVisualFamily ?? PageVisualFamily.classic;
    final variant =
        style?.vintagePaperVariant ?? VintagePaperVariant.parchment;
    final intensity = style?.animationIntensity ?? AnimationIntensity.subtle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _paperSpecFor(preset, isDark);
    final vintageSpec = _vintagePaperSpecFor(variant, isDark);

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
            final t = widget.animated && intensity.isAnimated
                ? _controller.value
                : 0.0;
            return Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color:
                          visualFamily == PageVisualFamily.vintage
                              ? vintageSpec.base
                              : spec.base,
                      gradient:
                          visualFamily == PageVisualFamily.vintage
                              ? _buildVintageGradient(vintageSpec, t, intensity)
                              : _buildGradient(spec, t),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter:
                          visualFamily == PageVisualFamily.vintage
                              ? _VintagePaperPainter(
                                spec: vintageSpec,
                                progress: t,
                                intensity: intensity,
                                drawLines: widget.lined,
                              )
                              : _PaperEffectPainter(spec: spec, progress: t),
                    ),
                  ),
                ),
                if (widget.lined && visualFamily != PageVisualFamily.vintage)
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

class _VintagePaperSpec {
  const _VintagePaperSpec({
    required this.base,
    required this.gradientA,
    required this.gradientB,
    required this.foxing,
    required this.edgeTint,
    required this.lineColor,
    required this.floralTint,
  });

  final Color base;
  final Color gradientA;
  final Color gradientB;
  final Color foxing;
  final Color edgeTint;
  final Color lineColor;
  final Color floralTint;
}

_VintagePaperSpec _vintagePaperSpecFor(
  VintagePaperVariant variant,
  bool isDark,
) {
  if (isDark) {
    switch (variant) {
      case VintagePaperVariant.sepiaDiary:
        return const _VintagePaperSpec(
          base: Color(0xFF2C241C),
          gradientA: Color(0xFF2E251C),
          gradientB: Color(0xFF201A14),
          foxing: Color(0xFF7D634B),
          edgeTint: Color(0xFF120F0C),
          lineColor: Color(0x33D8C6A8),
          floralTint: Color(0x338D7A63),
        );
      case VintagePaperVariant.pressedFloral:
        return const _VintagePaperSpec(
          base: Color(0xFF2A2519),
          gradientA: Color(0xFF312B1C),
          gradientB: Color(0xFF1F1A11),
          foxing: Color(0xFF7A6A4B),
          edgeTint: Color(0xFF110F0A),
          lineColor: Color(0x33D8CFAD),
          floralTint: Color(0x445E7E57),
        );
      case VintagePaperVariant.parchment:
        return const _VintagePaperSpec(
          base: Color(0xFF2C261A),
          gradientA: Color(0xFF312A1D),
          gradientB: Color(0xFF211A12),
          foxing: Color(0xFF7A6547),
          edgeTint: Color(0xFF100E09),
          lineColor: Color(0x33D6C7A2),
          floralTint: Color(0x336E6753),
        );
    }
  }

  switch (variant) {
    case VintagePaperVariant.sepiaDiary:
      return const _VintagePaperSpec(
        base: Color(0xFFF1E4CE),
        gradientA: Color(0xFFF5E9D6),
        gradientB: Color(0xFFE7D6B8),
        foxing: Color(0xFFA9885D),
        edgeTint: Color(0xFF7A5F3E),
        lineColor: Color(0x337A6243),
        floralTint: Color(0x337B5D3C),
      );
    case VintagePaperVariant.pressedFloral:
      return const _VintagePaperSpec(
        base: Color(0xFFF0E7D5),
        gradientA: Color(0xFFF7EDDE),
        gradientB: Color(0xFFE4D7BE),
        foxing: Color(0xFF9C835F),
        edgeTint: Color(0xFF6A5A43),
        lineColor: Color(0x336A5E4C),
        floralTint: Color(0x335C7F4E),
      );
    case VintagePaperVariant.parchment:
      return const _VintagePaperSpec(
        base: Color(0xFFF1E6CE),
        gradientA: Color(0xFFF9EEDB),
        gradientB: Color(0xFFE7D8BB),
        foxing: Color(0xFFA18159),
        edgeTint: Color(0xFF71593A),
        lineColor: Color(0x336E5A3E),
        floralTint: Color(0x335E5C55),
      );
  }
}

Gradient _buildVintageGradient(
  _VintagePaperSpec spec,
  double t,
  AnimationIntensity intensity,
) {
  final amplitude = switch (intensity) {
    AnimationIntensity.off => 0.0,
    AnimationIntensity.subtle => 0.06,
    AnimationIntensity.cinematic => 0.12,
  };
  final drift = sin(t * pi * 2) * amplitude;
  return LinearGradient(
    begin: Alignment(-0.9 + drift, -1.0),
    end: Alignment(0.9 - drift, 1.0),
    colors: [spec.gradientA, spec.base, spec.gradientB],
    stops: const [0.0, 0.55, 1.0],
  );
}

class _VintageBackdropPainter extends CustomPainter {
  const _VintageBackdropPainter({
    required this.spec,
    required this.progress,
    required this.intensity,
  });

  final _VintagePaperSpec spec;
  final double progress;
  final AnimationIntensity intensity;

  @override
  void paint(Canvas canvas, Size size) {
    final density = switch (intensity) {
      AnimationIntensity.off => 0,
      AnimationIntensity.subtle => 22,
      AnimationIntensity.cinematic => 38,
    };

    final grainPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.025)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 340; i++) {
      final x = _noise(i, 1.1) * size.width;
      final y = _noise(i, 2.3) * size.height;
      canvas.drawCircle(Offset(x, y), 0.7, grainPaint);
    }

    if (density == 0) return;

    final dustPaint = Paint();
    final drift = progress * pi * 2;
    for (int i = 0; i < density; i++) {
      final px = _noise(i * 17, 0.41) * size.width;
      final py = _noise(i * 31, 0.97) * size.height;
      final dx = sin(drift + i * 0.3) * (intensity == AnimationIntensity.cinematic ? 10 : 5);
      final dy = cos(drift * 0.75 + i * 0.2) * (intensity == AnimationIntensity.cinematic ? 5 : 2);
      dustPaint.color = Colors.white.withValues(
        alpha: intensity == AnimationIntensity.cinematic ? 0.065 : 0.04,
      );
      canvas.drawCircle(Offset(px + dx, py + dy), 1.4, dustPaint);
    }
  }

  double _noise(int seed, double shift) {
    final v = sin((seed * 12.9898) + shift) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _VintageBackdropPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.spec != spec;
  }
}

class _VintagePaperPainter extends CustomPainter {
  const _VintagePaperPainter({
    required this.spec,
    required this.progress,
    required this.intensity,
    required this.drawLines,
  });

  final _VintagePaperSpec spec;
  final double progress;
  final AnimationIntensity intensity;
  final bool drawLines;

  @override
  void paint(Canvas canvas, Size size) {
    final grainPaint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.03)
          ..style = PaintingStyle.fill;
    for (int i = 0; i < 620; i++) {
      final x = _noise(i, 0.7) * size.width;
      final y = _noise(i, 1.9) * size.height;
      final radius = 0.4 + _noise(i, 2.8) * 0.7;
      canvas.drawCircle(Offset(x, y), radius, grainPaint);
    }

    final foxingAlpha = switch (intensity) {
      AnimationIntensity.off => 0.12,
      AnimationIntensity.subtle => 0.16,
      AnimationIntensity.cinematic => 0.22,
    };
    final foxingPaint =
        Paint()
          ..color = spec.foxing.withValues(alpha: foxingAlpha)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.8);
    for (int i = 0; i < 24; i++) {
      final x = _noise(i * 13, 0.3) * size.width;
      final y = _noise(i * 29, 1.2) * size.height;
      final r = 8 + _noise(i * 7, 2.1) * 18;
      canvas.drawCircle(Offset(x, y), r, foxingPaint);
    }

    final edgeOverlay =
        Paint()
          ..shader = RadialGradient(
            center: const Alignment(0, -0.1),
            radius: 1.12,
            colors: [
              Colors.transparent,
              spec.edgeTint.withValues(alpha: 0.18),
            ],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgeOverlay);

    final foldPaint =
        Paint()
          ..color = spec.edgeTint.withValues(alpha: 0.08)
          ..strokeWidth = 1.2;
    final foldShift = intensity == AnimationIntensity.cinematic
        ? sin(progress * pi * 2) * 1.2
        : 0.0;
    final foldX = size.width * 0.32 + foldShift;
    canvas.drawLine(Offset(foldX, 0), Offset(foldX, size.height), foldPaint);

    if (drawLines) {
      final linePaint =
          Paint()
            ..color = spec.lineColor
            ..strokeWidth = 1.0;
      const topPadding = 64.0;
      const lineStep = 28.0;
      for (double y = topPadding; y < size.height; y += lineStep) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
      }
      canvas.drawLine(
        const Offset(48, 0),
        Offset(48, size.height),
        Paint()
          ..color = spec.lineColor.withValues(alpha: 0.65)
          ..strokeWidth = 1.3,
      );
    }

    _drawFloralHints(canvas, size);
  }

  void _drawFloralHints(Canvas canvas, Size size) {
    final petals =
        Paint()
          ..color = spec.floralTint.withValues(alpha: 0.26)
          ..style = PaintingStyle.fill;
    final stems =
        Paint()
          ..color = spec.floralTint.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    final accents = [
      Offset(size.width * 0.88, size.height * 0.14),
      Offset(size.width * 0.12, size.height * 0.82),
      Offset(size.width * 0.78, size.height * 0.78),
    ];

    for (final c in accents) {
      final stem = Path()
        ..moveTo(c.dx - 10, c.dy + 16)
        ..quadraticBezierTo(c.dx, c.dy + 6, c.dx + 14, c.dy + 22);
      canvas.drawPath(stem, stems);
      canvas.drawCircle(c, 5.5, petals);
      canvas.drawCircle(
        Offset(c.dx + 6, c.dy - 4),
        3.5,
        petals,
      );
    }
  }

  double _noise(int seed, double shift) {
    final v = sin((seed * 12.9898) + shift) * 43758.5453;
    return v - v.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _VintagePaperPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.intensity != intensity ||
        oldDelegate.drawLines != drawLines ||
        oldDelegate.spec != spec;
  }
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
