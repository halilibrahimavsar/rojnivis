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
    this.applyPageStudio = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final bool lined;
  final bool animated;
  final double? minHeight;
  final bool applyPageStudio;

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
    this.applyPageStudio = false,
  });

  final bool animated;
  final double opacity;
  final double blurSigma;
  final bool vignette;
  final bool applyPageStudio;

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
    final effectiveIntensity =
        widget.applyPageStudio
            ? Theme.of(context).extension<AppThemeStyle>()?.animationIntensity
            : null;
    final intensity = effectiveIntensity ?? AnimationIntensity.subtle;
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
    final visualFamily =
        widget.applyPageStudio
            ? style?.pageVisualFamily ?? PageVisualFamily.classic
            : PageVisualFamily.classic;
    final variant =
        widget.applyPageStudio
            ? style?.vintagePaperVariant ?? VintagePaperVariant.parchment
            : VintagePaperVariant.parchment;
    final intensity =
        widget.applyPageStudio
            ? style?.animationIntensity ?? AnimationIntensity.subtle
            : AnimationIntensity.subtle;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final spec = _paperSpecFor(preset, isDark);
    final vintageSpec = _vintagePaperSpecFor(variant, isDark);

    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          final t =
              widget.animated && intensity.isAnimated ? _controller.value : 0.0;
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
                child: Opacity(
                  opacity: _paperTextureOpacity(
                    visualFamily: visualFamily,
                    isDark: isDark,
                  ),
                  child: const Image(
                    image: AssetImage('assets/images/paper_texture.jpg'),
                    fit: BoxFit.cover,
                    filterQuality: FilterQuality.low,
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
    final effectiveIntensity =
        widget.applyPageStudio
            ? Theme.of(context).extension<AppThemeStyle>()?.animationIntensity
            : null;
    final intensity = effectiveIntensity ?? AnimationIntensity.subtle;
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
    final visualFamily =
        widget.applyPageStudio
            ? style?.pageVisualFamily ?? PageVisualFamily.classic
            : PageVisualFamily.classic;
    final variant =
        widget.applyPageStudio
            ? style?.vintagePaperVariant ?? VintagePaperVariant.parchment
            : VintagePaperVariant.parchment;
    final intensity =
        widget.applyPageStudio
            ? style?.animationIntensity ?? AnimationIntensity.subtle
            : AnimationIntensity.subtle;
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
            final t =
                widget.animated && intensity.isAnimated
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
                  child: Opacity(
                    opacity: _paperTextureOpacity(
                      visualFamily: visualFamily,
                      isDark: isDark,
                    ),
                    child: const Image(
                      image: AssetImage('assets/images/paper_texture.jpg'),
                      fit: BoxFit.cover,
                      filterQuality: FilterQuality.low,
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
                ? const [
                  Color(0xFF2A131A),
                  Color(0xFF351520),
                  Color(0xFF3B1B24),
                ]
                : const [
                  Color(0xFFFFF5F8),
                  Color(0xFFFFF2F6),
                  Color(0xFFFFD5E6),
                ],
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
        base: isDark ? const Color(0xFF04101B) : const Color(0xFFDAF0FF),
        gradient:
            isDark
                ? const [
                  Color(0xFF04101B),
                  Color(0xFF0A1E33),
                  Color(0xFF0F2E4A),
                ]
                : const [
                  Color(0xFFE7F6FF),
                  Color(0xFFC5E8FA),
                  Color(0xFFA3DAFF),
                ],
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
        base: isDark ? const Color(0xFF1E0F09) : const Color(0xFFFFF6EE),
        gradient:
            isDark
                ? const [
                  Color(0xFF1A0C08),
                  Color(0xFF2E1510),
                  Color(0xFF3A1B12),
                ]
                : const [
                  Color(0xFFFFF8F0),
                  Color(0xFFFFE4CC),
                  Color(0xFFFFCBA8),
                ],
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
        base: isDark ? const Color(0xFF0A150E) : const Color(0xFFEEF7EF),
        gradient:
            isDark
                ? const [
                  Color(0xFF081008),
                  Color(0xFF122018),
                  Color(0xFF1A3022),
                ]
                : const [
                  Color(0xFFF3FAF4),
                  Color(0xFFE0F0DD),
                  Color(0xFFCDE5C8),
                ],
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
        base: isDark ? const Color(0xFF0E1C14) : const Color(0xFFF8FFF6),
        gradient:
            isDark
                ? const [
                  Color(0xFF0E1C14),
                  Color(0xFF162518),
                  Color(0xFF1E301F),
                ]
                : const [
                  Color(0xFFFBFFF9),
                  Color(0xFFF0FDE8),
                  Color(0xFFE6FCDF),
                ],
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
        base: isDark ? const Color(0xFF1A100A) : const Color(0xFFFFF9F2),
        gradient:
            isDark
                ? const [
                  Color(0xFF180E08),
                  Color(0xFF24150C),
                  Color(0xFF301E12),
                ]
                : const [
                  Color(0xFFFFFAF2),
                  Color(0xFFFFEDD5),
                  Color(0xFFFFDFB8),
                ],
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
  // Compute evenly spaced stops for any gradient length
  final stops = List<double>.generate(
    spec.gradient.length,
    (i) => i / (spec.gradient.length - 1),
  );
  if (spec.motif == _PaperMotif.sun) {
    return RadialGradient(
      center: Alignment(0.7 + drift, -0.6),
      radius: 1.3,
      colors: spec.gradient,
      stops: stops,
    );
  }
  return LinearGradient(
    begin: Alignment(-0.9 + drift, -1.0),
    end: Alignment(0.9 - drift, 1.0),
    colors: spec.gradient,
    stops: stops,
  );
}

double _paperTextureOpacity({
  required PageVisualFamily visualFamily,
  required bool isDark,
}) {
  if (visualFamily == PageVisualFamily.vintage) {
    return isDark ? 0.08 : 0.14;
  }
  return isDark ? 0.04 : 0.09;
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
      final dx =
          sin(drift + i * 0.3) *
          (intensity == AnimationIntensity.cinematic ? 10 : 5);
      final dy =
          cos(drift * 0.75 + i * 0.2) *
          (intensity == AnimationIntensity.cinematic ? 5 : 2);
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
            colors: [Colors.transparent, spec.edgeTint.withValues(alpha: 0.18)],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, edgeOverlay);

    final foldPaint =
        Paint()
          ..color = spec.edgeTint.withValues(alpha: 0.08)
          ..strokeWidth = 1.2;
    final foldShift =
        intensity == AnimationIntensity.cinematic
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
      final stem =
          Path()
            ..moveTo(c.dx - 10, c.dy + 16)
            ..quadraticBezierTo(c.dx, c.dy + 6, c.dx + 14, c.dy + 22);
      canvas.drawPath(stem, stems);
      canvas.drawCircle(c, 5.5, petals);
      canvas.drawCircle(Offset(c.dx + 6, c.dy - 4), 3.5, petals);
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
        _drawRealisticHearts(canvas, size);
        break;
      case _PaperMotif.waves:
        _drawRealisticOcean(canvas, size);
        break;
      case _PaperMotif.petals:
        _drawRealisticSpring(canvas, size);
        break;
      case _PaperMotif.leaves:
        _drawRealisticLeaves(canvas, size);
        break;
      case _PaperMotif.sun:
        _drawRealisticSunset(canvas, size);
        break;
      case _PaperMotif.grid:
        _drawRealisticGrid(canvas, size);
        break;
      case _PaperMotif.bubbles:
        _drawRealisticBubbles(canvas, size);
        break;
      case _PaperMotif.none:
        break;
    }
  }

  // ── Ocean: multi-layered waves with foam and caustic shimmer ──
  void _drawRealisticOcean(Canvas canvas, Size size) {
    // Atmospheric depth gradient
    final depthPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              spec.accent.withValues(alpha: 0.03),
              spec.accent2.withValues(alpha: 0.08),
              spec.accent.withValues(alpha: 0.12),
            ],
          ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, depthPaint);

    // Caustic light shimmer
    final causticPaint =
        Paint()
          ..color = spec.accent2.withValues(alpha: 0.06)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    final rng = Random(88);
    for (int i = 0; i < 18; i++) {
      final cx = rng.nextDouble() * size.width;
      final cy = rng.nextDouble() * size.height;
      final drift = sin(progress * pi * 2 + i * 1.7) * 8;
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + drift, cy),
          width: 30 + rng.nextDouble() * 50,
          height: 12 + rng.nextDouble() * 20,
        ),
        causticPaint,
      );
    }

    // 5 layered wave crests with decreasing opacity
    for (int layer = 0; layer < 5; layer++) {
      final layerT = layer / 4.0;
      final baseY = size.height * (0.25 + layerT * 0.18);
      final amplitude = 6.0 + layer * 5;
      final freq = 1.8 + layer * 0.5;
      final phase = progress * pi * 2 * (0.4 + layer * 0.15);
      final alpha = 0.06 + layerT * 0.10;

      final wavePath = Path();
      wavePath.moveTo(-10, size.height);
      wavePath.lineTo(-10, baseY);
      for (double x = -10; x <= size.width + 10; x += 4) {
        final y1 = sin((x / size.width) * pi * freq + phase) * amplitude;
        final y2 =
            sin((x / size.width) * pi * (freq * 1.3) + phase * 0.7) *
            amplitude *
            0.4;
        wavePath.lineTo(x, baseY + y1 + y2);
      }
      wavePath.lineTo(size.width + 10, size.height);
      wavePath.close();

      canvas.drawPath(
        wavePath,
        Paint()..color = spec.accent.withValues(alpha: alpha),
      );

      // Foam highlights on wave crests
      final foamPaint =
          Paint()
            ..color = Colors.white.withValues(alpha: alpha * 0.5)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0 + layerT;
      final foamPath = Path();
      foamPath.moveTo(0, baseY);
      for (double x = 0; x <= size.width; x += 4) {
        final y1 = sin((x / size.width) * pi * freq + phase) * amplitude;
        final y2 =
            sin((x / size.width) * pi * (freq * 1.3) + phase * 0.7) *
            amplitude *
            0.4;
        foamPath.lineTo(x, baseY + y1 + y2 - 1.5);
      }
      canvas.drawPath(foamPath, foamPaint);
    }
  }

  // ── Sunset: volumetric sun glow, cloud bands, light rays ──
  void _drawRealisticSunset(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.75, size.height * 0.22);
    final sunRadius = size.shortestSide * 0.14;

    // Multi-ring sun glow
    for (int ring = 4; ring >= 0; ring--) {
      final r = sunRadius * (1.0 + ring * 0.8);
      final alpha = 0.04 + (4 - ring) * 0.05;
      canvas.drawCircle(
        sunCenter,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [spec.accent.withValues(alpha: alpha), Colors.transparent],
          ).createShader(Rect.fromCircle(center: sunCenter, radius: r)),
      );
    }

    // Sun core
    canvas.drawCircle(
      sunCenter,
      sunRadius * 0.5,
      Paint()..color = spec.accent.withValues(alpha: 0.22),
    );

    // God rays from sun
    final rayPaint =
        Paint()
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;
    for (int i = 0; i < 12; i++) {
      final angle = (i / 12.0) * pi * 2 + progress * pi * 0.3;
      final len = sunRadius * (2.0 + sin(progress * pi * 2 + i) * 0.6);
      final endX = sunCenter.dx + cos(angle) * len;
      final endY = sunCenter.dy + sin(angle) * len;
      rayPaint.shader = LinearGradient(
        colors: [spec.accent.withValues(alpha: 0.12), Colors.transparent],
      ).createShader(Rect.fromPoints(sunCenter, Offset(endX, endY)));
      canvas.drawLine(sunCenter, Offset(endX, endY), rayPaint);
    }

    // Cloud bands
    for (int i = 0; i < 4; i++) {
      final cloudY = size.height * (0.38 + i * 0.14);
      final drift = sin(progress * pi * 2 + i * 2.1) * 12;
      final cloudPath = Path();
      cloudPath.moveTo(-20, cloudY + 10);
      final rng = Random(i * 37 + 5);
      for (double x = -20; x <= size.width + 20; x += 20) {
        final bumpH = 4.0 + rng.nextDouble() * 10;
        cloudPath.quadraticBezierTo(
          x + 10 + drift,
          cloudY - bumpH,
          x + 20 + drift,
          cloudY,
        );
      }
      cloudPath.lineTo(size.width + 20, cloudY + 30);
      cloudPath.lineTo(-20, cloudY + 30);
      cloudPath.close();

      final cloudColor =
          i < 2
              ? spec.accent.withValues(alpha: 0.06 + i * 0.02)
              : spec.accent2.withValues(alpha: 0.04 + i * 0.01);
      canvas.drawPath(
        cloudPath,
        Paint()
          ..color = cloudColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }
  }

  // ── Forest / Autumn leaves: volumetric light rays + realistic leaves ──
  void _drawRealisticLeaves(Canvas canvas, Size size) {
    // Dappled sunlight rays from top
    for (int i = 0; i < 5; i++) {
      final rng = Random(i * 13 + 7);
      final rayX = rng.nextDouble() * size.width;
      final rayW = 20.0 + rng.nextDouble() * 40;
      final sway = sin(progress * pi * 2 + i * 1.5) * 6;
      final rayPaint =
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                spec.accent2.withValues(alpha: 0.10),
                spec.accent2.withValues(alpha: 0.02),
                Colors.transparent,
              ],
            ).createShader(
              Rect.fromLTWH(rayX + sway, 0, rayW, size.height * 0.7),
            );
      canvas.drawRect(
        Rect.fromLTWH(rayX + sway, 0, rayW, size.height * 0.7),
        rayPaint,
      );
    }

    // Floating realistic leaves
    final rng = Random(11);
    for (int i = 0; i < 16; i++) {
      final x = rng.nextDouble();
      final y = rng.nextDouble();
      final speed = lerpDouble(0.015, 0.05, rng.nextDouble())!;
      final sway = sin(progress * pi * 2 * (0.5 + rng.nextDouble()) + i) * 0.03;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final dx = x + sway;
      final leafSize = lerpDouble(10, 22, rng.nextDouble())!;
      final angle = progress * pi * 2 * (0.2 + rng.nextDouble() * 0.3);
      // Multi-toned leaf color
      final leafColor =
          i.isEven
              ? spec.accent.withValues(alpha: 0.14 + rng.nextDouble() * 0.06)
              : spec.accent2.withValues(alpha: 0.12 + rng.nextDouble() * 0.06);
      _paintRealisticLeaf(
        canvas,
        Offset(dx * size.width, dy * size.height),
        leafSize,
        angle,
        leafColor,
      );
    }
  }

  // ── Spring: cherry blossoms with veining ──
  void _drawRealisticSpring(Canvas canvas, Size size) {
    // Soft bokeh glow background spots
    final bokehPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18);
    final rng = Random(3);
    for (int i = 0; i < 8; i++) {
      final bx = rng.nextDouble() * size.width;
      final by = rng.nextDouble() * size.height;
      final drift = sin(progress * pi * 2 + i * 2.3) * 6;
      bokehPaint.color =
          i.isEven
              ? spec.accent.withValues(alpha: 0.05)
              : spec.accent2.withValues(alpha: 0.04);
      canvas.drawCircle(
        Offset(bx + drift, by),
        16 + rng.nextDouble() * 24,
        bokehPaint,
      );
    }

    // Falling petals with realistic shape
    final petalRng = Random(7);
    for (int i = 0; i < 20; i++) {
      final x = petalRng.nextDouble();
      final y = petalRng.nextDouble();
      final speed = lerpDouble(0.02, 0.06, petalRng.nextDouble())!;
      final sway =
          sin(progress * pi * 2 * (0.6 + petalRng.nextDouble()) + i) * 0.025;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final dx = x + sway;
      final petalSize = lerpDouble(6, 16, petalRng.nextDouble())!;
      final angle = progress * pi * 2 * (0.3 + petalRng.nextDouble() * 0.4);
      final alpha = 0.10 + petalRng.nextDouble() * 0.10;
      _paintCherryPetal(
        canvas,
        Offset(dx * size.width, dy * size.height),
        petalSize,
        angle,
        spec.accent.withValues(alpha: alpha),
      );
    }
  }

  // ── Love: bokeh hearts with glow ──
  void _drawRealisticHearts(Canvas canvas, Size size) {
    // Warm bokeh glow
    final glowPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20);
    final rng = Random(42);
    for (int i = 0; i < 10; i++) {
      final gx = rng.nextDouble() * size.width;
      final gy = rng.nextDouble() * size.height;
      final drift = sin(progress * pi * 2 + i * 1.4) * 5;
      glowPaint.color = spec.accent.withValues(
        alpha: 0.04 + rng.nextDouble() * 0.03,
      );
      canvas.drawCircle(
        Offset(gx + drift, gy),
        20 + rng.nextDouble() * 30,
        glowPaint,
      );
    }

    // Floating hearts with soft edges
    final heartRng = Random(42);
    for (int i = 0; i < 14; i++) {
      final x = heartRng.nextDouble();
      final y = heartRng.nextDouble();
      final speed = lerpDouble(0.02, 0.08, heartRng.nextDouble())!;
      final drift = heartRng.nextDouble();
      final dy = (y - progress * speed + 1.2) % 1.2 - 0.1;
      final dx = x + sin((progress + drift) * pi * 2) * 0.02;
      final sizeFactor = lerpDouble(8, 20, heartRng.nextDouble())!;
      final alpha = 0.06 + heartRng.nextDouble() * 0.10;
      // Heart with glow halo
      final center = Offset(dx * size.width, dy * size.height);
      _paintHeart(
        canvas,
        center,
        sizeFactor + 4,
        Paint()
          ..color = spec.accent.withValues(alpha: alpha * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );
      _paintHeart(
        canvas,
        center,
        sizeFactor,
        Paint()..color = spec.accent.withValues(alpha: alpha),
      );
    }
  }

  // ── Futuristic grid: scan lines + neon pulse ──
  void _drawRealisticGrid(Canvas canvas, Size size) {
    // Subtle scan line effect
    final scanPaint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.04)
          ..strokeWidth = 0.5;
    for (double y = 0; y <= size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), scanPaint);
    }
    // Grid
    final gridPaint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.06)
          ..strokeWidth = 0.8;
    const step = 48.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Neon pulse nodes at intersections
    final nodePaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    final rng = Random(9);
    for (double x = step; x < size.width; x += step) {
      for (double y = step; y < size.height; y += step) {
        if (rng.nextDouble() > 0.35) continue;
        final pulse = sin(progress * pi * 2 + x * 0.01 + y * 0.02) * 0.5 + 0.5;
        nodePaint.color = spec.accent.withValues(alpha: 0.05 + pulse * 0.08);
        canvas.drawCircle(Offset(x, y), 2.5 + pulse * 1.5, nodePaint);
      }
    }
  }

  // ── Glass: refraction bubbles with light sheen ──
  void _drawRealisticBubbles(Canvas canvas, Size size) {
    final rng = Random(21);
    for (int i = 0; i < 14; i++) {
      final x = rng.nextDouble() * size.width;
      final rawY = rng.nextDouble();
      final y =
          ((rawY + progress * 0.06) % 1.1) * size.height - size.height * 0.05;
      final radius = lerpDouble(14, 38, rng.nextDouble())!;
      final center = Offset(x, y);

      // Bubble body
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = spec.accent.withValues(alpha: 0.06)
          ..style = PaintingStyle.fill,
      );
      // Rim
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..color = spec.accent.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
      // Specular highlight arc
      final highlightRect = Rect.fromCircle(
        center: Offset(center.dx - radius * 0.25, center.dy - radius * 0.3),
        radius: radius * 0.5,
      );
      canvas.drawArc(
        highlightRect,
        -pi * 0.8,
        pi * 0.7,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.12)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  // ── Shape helpers ──

  void _paintHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    final w = size;
    final h = size;
    path.moveTo(center.dx, center.dy + h * 0.35);
    path.cubicTo(
      center.dx + w * 0.5,
      center.dy - h * 0.2,
      center.dx + w * 1.1,
      center.dy + h * 0.25,
      center.dx,
      center.dy + h,
    );
    path.cubicTo(
      center.dx - w * 1.1,
      center.dy + h * 0.25,
      center.dx - w * 0.5,
      center.dy - h * 0.2,
      center.dx,
      center.dy + h * 0.35,
    );
    canvas.drawPath(path, paint);
  }

  void _paintRealisticLeaf(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    // Leaf body
    final body =
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(size * 0.5, -size * 0.9, size * 1.1, 0)
          ..quadraticBezierTo(size * 0.5, size * 0.9, 0, 0);
    canvas.drawPath(body, Paint()..color = color);
    // Center vein
    canvas.drawLine(
      Offset.zero,
      Offset(size * 1.1, 0),
      Paint()
        ..color = color.withValues(alpha: (color.a * 1.4).clamp(0.0, 1.0))
        ..strokeWidth = 0.6,
    );
    canvas.restore();
  }

  void _paintCherryPetal(
    Canvas canvas,
    Offset center,
    double size,
    double angle,
    Color color,
  ) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    // 5-petal cherry shape (draw one rounded petal shape)
    final path =
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(size * 0.4, -size * 0.8, size * 0.9, -size * 0.2)
          ..quadraticBezierTo(size * 1.0, size * 0.3, size * 0.4, size * 0.4)
          ..quadraticBezierTo(size * 0.1, size * 0.5, 0, 0);
    canvas.drawPath(path, Paint()..color = color);
    // Subtle inner vein
    canvas.drawLine(
      Offset(size * 0.1, 0),
      Offset(size * 0.6, -size * 0.1),
      Paint()
        ..color = color.withValues(alpha: (color.a * 0.6).clamp(0.0, 1.0))
        ..strokeWidth = 0.4,
    );
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
