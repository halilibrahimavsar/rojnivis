import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  // Interactivity
  double _pointerX = -100;
  double _pointerY = -100;
  bool _isPointerDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    );
  }

  Map<String, ui.Image> _cache = {};
  bool _loading = false;
  AppThemePreset? _lastPreset;

  Future<void> _loadSprites(AppThemePreset preset) async {
    if (_loading || _lastPreset == preset) return;
    _loading = true;
    _lastPreset = preset;

    final paths = <String>[];
    switch (preset) {
      case AppThemePreset.snowing:
        paths.add('assets/images/particles/snowflake.png');
      case AppThemePreset.raining:
      case AppThemePreset.storm:
        paths.add('assets/images/particles/raindrop.png');
      case AppThemePreset.autumn:
      case AppThemePreset.nature:
      case AppThemePreset.forest:
        paths.add('assets/images/particles/leaf_autumn.png');
        paths.add('assets/images/particles/leaf_green.png');
      case AppThemePreset.darkNature:
        paths.add('assets/images/particles/leaf_autumn.png');
        paths.add('assets/images/particles/leaf_green.png');
        paths.add('assets/images/particles/firefly.png');
      case AppThemePreset.spring:
        paths.add('assets/images/particles/petal.png');
      case AppThemePreset.love:
        paths.add('assets/images/particles/heart.png');
      case AppThemePreset.glass:
        paths.add('assets/images/particles/bubble.png');
      case AppThemePreset.nightblue:
      case AppThemePreset.nebula:
        paths.add('assets/images/particles/star.png');
      case AppThemePreset.nightmare:
        paths.add('assets/images/particles/smoke.png');
      default:
        break;
    }

    final newCache = <String, ui.Image>{};
    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        newCache[path] = frame.image;
      } catch (e) {
        debugPrint('Failed to load sprite: $path');
      }
    }

    if (mounted) {
      setState(() {
        _cache = newCache;
        _loading = false;
      });
    }
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

    if (_lastPreset != preset) {
      _loadSprites(preset);
    }

    return MouseRegion(
      onHover: (e) {
        if (mounted) {
          setState(() {
            _pointerX = e.localPosition.dx;
            _pointerY = e.localPosition.dy;
          });
        }
      },
      onExit: (_) {
        if (mounted) {
          setState(() {
            _pointerX = -100;
            _pointerY = -100;
            _isPointerDown = false;
          });
        }
      },
      child: GestureDetector(
        onPanUpdate: (e) {
          if (mounted) {
            setState(() {
              _pointerX = e.localPosition.dx;
              _pointerY = e.localPosition.dy;
              _isPointerDown = true;
            });
          }
        },
        onPanEnd: (_) {
          if (mounted) setState(() => _isPointerDown = false);
        },
        onPanCancel: () {
          if (mounted) setState(() => _isPointerDown = false);
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final t =
                widget.animated && intensity.isAnimated
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
                if (visualFamily != PageVisualFamily.vintage)
                  _buildBackgroundImage(preset, t, isBackdrop: true),
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
                              : _PaperEffectPainter(
                                spec: spec,
                                progress: t,
                                sprites: _cache,
                                pointerX: _pointerX,
                                pointerY: _pointerY,
                                isPointerDown: _isPointerDown,
                              ),
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
                      filter: ui.ImageFilter.blur(
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
      ),
    );
  }
}

class _ThemedPaperState extends State<ThemedPaper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _isRepeating = false;

  // Interactivity
  double _pointerX = -100;
  double _pointerY = -100;
  bool _isPointerDown = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    );
  }

  Map<String, ui.Image> _cache = {};
  bool _loading = false;
  AppThemePreset? _lastPreset;

  Future<void> _loadSprites(AppThemePreset preset) async {
    if (_loading || _lastPreset == preset) return;
    _loading = true;
    _lastPreset = preset;

    final paths = <String>[];
    switch (preset) {
      case AppThemePreset.snowing:
        paths.add('assets/images/particles/snowflake.png');
      case AppThemePreset.raining:
      case AppThemePreset.storm:
        paths.add('assets/images/particles/raindrop.png');
      case AppThemePreset.autumn:
      case AppThemePreset.nature:
      case AppThemePreset.forest:
        paths.add('assets/images/particles/leaf_autumn.png');
        paths.add('assets/images/particles/leaf_green.png');
      case AppThemePreset.darkNature:
        paths.add('assets/images/particles/leaf_autumn.png');
        paths.add('assets/images/particles/leaf_green.png');
        paths.add('assets/images/particles/firefly.png');
      case AppThemePreset.spring:
        paths.add('assets/images/particles/petal.png');
      case AppThemePreset.love:
        paths.add('assets/images/particles/heart.png');
      case AppThemePreset.glass:
        paths.add('assets/images/particles/bubble.png');
      case AppThemePreset.nightblue:
      case AppThemePreset.nebula:
        paths.add('assets/images/particles/star.png');
      case AppThemePreset.nightmare:
        paths.add('assets/images/particles/smoke.png');
      default:
        break;
    }

    final newCache = <String, ui.Image>{};
    for (final path in paths) {
      try {
        final data = await rootBundle.load(path);
        final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
        final frame = await codec.getNextFrame();
        newCache[path] = frame.image;
      } catch (e) {
        debugPrint('Failed to load sprite: $path');
      }
    }

    if (mounted) {
      setState(() {
        _cache = newCache;
        _loading = false;
      });
    }
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

    if (_lastPreset != preset) {
      _loadSprites(preset);
    }

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
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: (e) {
            if (mounted) {
              setState(() {
                _isPointerDown = true;
                _pointerX = e.localPosition.dx;
                _pointerY = e.localPosition.dy;
              });
            }
          },
          onPointerMove: (e) {
            if (mounted) {
              setState(() {
                _pointerX = e.localPosition.dx;
                _pointerY = e.localPosition.dy;
              });
            }
          },
          onPointerUp: (_) {
            if (mounted) setState(() => _isPointerDown = false);
          },
          onPointerCancel: (_) {
            if (mounted) setState(() => _isPointerDown = false);
          },
          onPointerHover: (e) {
            if (mounted) {
              setState(() {
                _pointerX = e.localPosition.dx;
                _pointerY = e.localPosition.dy;
              });
            }
          },
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
                                ? _buildVintageGradient(
                                  vintageSpec,
                                  t,
                                  intensity,
                                )
                                : _buildGradient(spec, t),
                      ),
                    ),
                  ),
                  if (visualFamily != PageVisualFamily.vintage)
                    _buildBackgroundImage(preset, t, isBackdrop: false),
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
                                : _PaperEffectPainter(
                                  spec: spec,
                                  progress: t,
                                  sprites: _cache,
                                  pointerX: _pointerX,
                                  pointerY: _pointerY,
                                  isPointerDown: _isPointerDown,
                                ),
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
      ),
    );
  }
}

enum _PaperMotif {
  none,
  hearts,
  waves,
  petals,
  leaves,
  sun,
  grid,
  bubbles,
  fog,
  stars,
  fireflies,
  aurora,
  storm,
  nebula,
  raining,
  snowing,
  sunny,
}

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
      return _paperSpecFor(AppThemePreset.defaultPreset, isDark);
    case AppThemePreset.nightmare:
      return _PaperSpec(
        base: const Color(0xFF0F0505),
        gradient: const [
          Color(0xFF0F0505),
          Color(0xFF1A0505),
          Color(0xFF2B0A0A),
        ],
        accent: const Color(0xFF8B0000), // Dark Red
        accent2: const Color(0xFF4A0404), // Blood Red
        lineColor: Colors.white.withValues(alpha: 0.04),
        motif: _PaperMotif.fog,
      );
    case AppThemePreset.nightblue:
      return _PaperSpec(
        base: const Color(0xFF02040A),
        gradient: const [
          Color(0xFF02040A),
          Color(0xFF0A1020),
          Color(0xFF152040),
        ],
        accent: const Color(0xFFE6E6FA), // Lavender stars
        accent2: const Color(0xFF4169E1), // Royal Blue glow
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.stars,
      );
    case AppThemePreset.sunrise:
      return _PaperSpec(
        base: isDark ? const Color(0xFF2D1B1E) : const Color(0xFFFFF9F5),
        gradient:
            isDark
                ? const [
                  Color(0xFF2D1B1E),
                  Color(0xFF4A2C30),
                  Color(0xFF633A33),
                ]
                : const [
                  Color(0xFFFFF9F5),
                  Color(0xFFFFECE6),
                  Color(0xFFFFDAB9),
                ],
        accent: const Color(0xFFFF9A8B),
        accent2: const Color(0xFFFFD700),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.sun,
      );
    case AppThemePreset.nature:
      return _PaperSpec(
        base: isDark ? const Color(0xFF1B261D) : const Color(0xFFF9FFF6),
        gradient:
            isDark
                ? const [
                  Color(0xFF1B261D),
                  Color(0xFF28382B),
                  Color(0xFF364A38),
                ]
                : const [
                  Color(0xFFF9FFF6),
                  Color(0xFFEDF7EB),
                  Color(0xFFDCEDD9),
                ],
        accent: const Color(0xFF558B2F),
        accent2: const Color(0xFF8BC34A),
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.leaves,
      );
    case AppThemePreset.darkNature:
      return _PaperSpec(
        base: const Color(0xFF001512),
        gradient: const [
          Color(0xFF001512),
          Color(0xFF00221E),
          Color(0xFF00332D),
        ],
        accent: const Color(0xFF1DE9B6), // Teal accent
        accent2: const Color(0xFFB2FF59), // Firefly glow
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.fireflies,
      );

    case AppThemePreset.aurora:
      return _PaperSpec(
        base: const Color(0xFF061A14),
        gradient: const [
          Color(0xFF061A14),
          Color(0xFF0F2E23),
          Color(0xFF162030), // Fade to night sky
        ],
        accent: const Color(0xFF00E676), // Green Aurora
        accent2: const Color(0xFF651FFF), // Purple Aurora
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.aurora,
      );

    case AppThemePreset.storm:
      return _PaperSpec(
        base: const Color(0xFF121416),
        gradient: const [
          Color(0xFF101416), // Dark Grey
          Color(0xFF1C2226),
          Color(0xFF263238),
        ],
        accent: const Color(0xFF546E7A), // Cloud Grey
        accent2: const Color(0xFFFFD600), // Lightning
        lineColor: Colors.white.withValues(alpha: 0.04),
        motif: _PaperMotif.storm,
      );

    case AppThemePreset.nebula:
      return _PaperSpec(
        base: const Color(0xFF120316),
        gradient: const [
          Color(0xFF120316),
          Color(0xFF200A26),
          Color(0xFF100010),
        ],
        accent: const Color(0xFF9C27B0), // Purple Gas
        accent2: const Color(0xFFFF4081), // Pink Gas
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.nebula,
      );

    case AppThemePreset.raining:
      return _PaperSpec(
        base: const Color(0xFF151B1E),
        gradient: const [
          Color(0xFF151B1E),
          Color(0xFF20262A),
          Color(0xFF2C353B),
        ],
        accent: const Color(0xFF90A4AE), // Rain grey
        accent2: const Color(0xFFB0BEC5), // Ripple light
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.raining,
      );

    case AppThemePreset.snowing:
      return _PaperSpec(
        base: const Color(0xFF0F171C),
        gradient: const [
          Color(0xFF0F171C),
          Color(0xFF162026),
          Color(0xFF222D35),
        ],
        accent: const Color(0xFFE1F5FE), // Snow white/blue
        accent2: const Color(0xFF81D4FA), // Ice blue
        lineColor: Colors.white.withValues(alpha: 0.05),
        motif: _PaperMotif.snowing,
      );

    case AppThemePreset.sunny:
      return _PaperSpec(
        base: isDark ? const Color(0xFF3E2723) : const Color(0xFFFFFDE7),
        gradient:
            isDark
                ? const [Color(0xFF3E2723), Color(0xFF4E342E)]
                : const [
                  Color(0xFFFFFDE7),
                  Color(0xFFFFF9C4),
                  Color(0xFFFFF59D),
                ],
        accent: const Color(0xFFFFC107), // Sun Amber
        accent2: const Color(0xFFFF9800), // Sun Orange
        lineColor:
            isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
        motif: _PaperMotif.sunny,
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

String? _bgImageFor(AppThemePreset preset) {
  return switch (preset) {
    AppThemePreset.aurora => 'assets/images/backgrounds/aurora.png',
    AppThemePreset.storm => 'assets/images/backgrounds/storm.png',
    AppThemePreset.nebula => 'assets/images/backgrounds/nebula.png',
    AppThemePreset.raining => 'assets/images/backgrounds/raining.png',
    AppThemePreset.snowing => 'assets/images/backgrounds/snowing.png',
    AppThemePreset.sunny => 'assets/images/backgrounds/sunny.png',
    AppThemePreset.nightblue => 'assets/images/backgrounds/nightblue.png',
    AppThemePreset.darkNature => 'assets/images/backgrounds/darknature.png',
    AppThemePreset.autumn => 'assets/images/backgrounds/autumn.png',
    AppThemePreset.spring => 'assets/images/backgrounds/spring.png',
    AppThemePreset.ocean => 'assets/images/backgrounds/ocean.png',
    AppThemePreset.love => 'assets/images/backgrounds/love.png',
    AppThemePreset.nightmare => 'assets/images/backgrounds/nightmare.png',
    AppThemePreset.sunset => 'assets/images/backgrounds/sunset.png',
    AppThemePreset.forest => 'assets/images/backgrounds/forest.png',
    AppThemePreset.futuristic => 'assets/images/backgrounds/futuristic.png',
    AppThemePreset.glass => 'assets/images/backgrounds/glass.png',
    AppThemePreset.nature => 'assets/images/backgrounds/nature.png',
    AppThemePreset.sunrise => 'assets/images/backgrounds/sunset.png',
    _ => null,
  };
}

Widget _buildBackgroundImage(
  AppThemePreset preset,
  double t, {
  required bool isBackdrop,
}) {
  final path = _bgImageFor(preset);
  if (path == null) return const SizedBox.shrink();

  // Subtle Ken Burns motion
  final scale = 1.1 + sin(t * pi * 2) * 0.04;
  final panX = cos(t * pi * 2) * 15.0;
  final panY = sin(t * pi * 2) * 10.0;
  final skewX = sin(t * pi * 4) * 0.015;

  return Positioned.fill(
    child: ClipRect(
      child: Transform(
        transform:
            Matrix4.identity()
              ..scale(scale)
              ..translate(panX, panY),
        alignment: Alignment.center,
        child: Transform(
          transform: Matrix4.skewX(skewX),
          alignment: Alignment.bottomCenter,
          child: Opacity(
            opacity: isBackdrop ? 0.7 : 0.4,
            child: Image.asset(path, fit: BoxFit.cover),
          ),
        ),
      ),
    ),
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
  _PaperEffectPainter({
    required this.spec,
    required this.progress,
    this.sprites,
    this.pointerX = -100,
    this.pointerY = -100,
    this.isPointerDown = false,
  });

  final _PaperSpec spec;
  final double progress;
  final Map<String, ui.Image>? sprites;
  final double pointerX;
  final double pointerY;
  final bool isPointerDown;

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
      case _PaperMotif.fog:
        _drawRealisticFog(canvas, size);
        break;
      case _PaperMotif.stars:
        _drawRealisticStars(canvas, size);
        break;
      case _PaperMotif.fireflies:
        _drawRealisticFireflies(canvas, size);
        break;
      case _PaperMotif.aurora:
        _drawRealisticAurora(canvas, size);
        break;
      case _PaperMotif.storm:
        _drawRealisticStorm(canvas, size);
        break;
      case _PaperMotif.nebula:
        _drawRealisticNebula(canvas, size);
        break;
      case _PaperMotif.raining:
        _drawRealisticRain(canvas, size);
        break;
      case _PaperMotif.snowing:
        _drawRealisticSnow(canvas, size);
        break;
      case _PaperMotif.sunny:
        _drawRealisticSunny(canvas, size);
        break;
      case _PaperMotif.none:
        break;
    }

    // Always draw swaying plants for nature-themed presets
    if (spec.motif == _PaperMotif.leaves ||
        spec.motif == _PaperMotif.fireflies ||
        spec.motif == _PaperMotif.petals ||
        spec.motif == _PaperMotif.raining) {
      _drawSwayingPlants(canvas, size);
    }

    // ** Antigravity's Added Perk: Magic Shine particles on touch! **
    if (isPointerDown) {
      _drawMagicShine(canvas, size);
    }
  }

  void _drawMagicShine(Canvas canvas, Size size) {
    final rng = Random(DateTime.now().millisecondsSinceEpoch ~/ 100);
    final paint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    for (int i = 0; i < 8; i++) {
      final t = (progress * 2.0 + i / 8) % 1.0;
      final angle = (i / 8) * pi * 2 + progress * pi;
      // Use rng for subtle jitter
      final jitter = (rng.nextDouble() - 0.5) * 5.0;
      final dist = 10.0 + 40.0 * t + jitter;
      final px = pointerX + cos(angle) * dist;
      final py = pointerY + sin(angle) * dist;
      final s = 2.0 * (1.0 - t);
      paint.color = spec.accent2.withValues(alpha: 0.4 * (1.0 - t));
      canvas.drawCircle(Offset(px, py), s, paint);
    }
  }

  // ── Rain: Heavy rain + ripples ──
  void _drawRealisticRain(Canvas canvas, Size size) {
    final rng = Random(1337);
    final rainPaint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.15)
          ..strokeWidth = 1.0;

    // Falling rain — varied depth for parallax
    final sprite = sprites?['assets/images/particles/raindrop.png'];

    for (int i = 0; i < 160; i++) {
      final depth = rng.nextDouble();
      final xBase = rng.nextDouble() * size.width;
      final speed = 1.5 + (depth * 4.0); // Faster close rain
      final yBase =
          (rng.nextDouble() + progress * speed) % 1.2 * size.height -
          size.height * 0.1;

      double x = xBase;
      double y = yBase;

      // ** Interaction: Rain parts around finger **
      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        final affectRadius = 130.0;
        if (dist < affectRadius && dist > 0.1) {
          final force = (affectRadius - dist) / affectRadius;
          x += (dx / dist) * force * 60.0;
        }
      }

      // 3D Depth effects: closer is bigger, longer, and brighter
      final length = 15.0 + 35.0 * depth;
      final alpha = 0.05 + 0.35 * depth;
      final stroke = 0.5 + 2.5 * depth;

      if (sprite != null) {
        final rect = Rect.fromLTWH(x, y, stroke, length);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          rect,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      } else {
        rainPaint
          ..color = spec.accent.withValues(alpha: alpha)
          ..strokeWidth = stroke;
        // Tilted rain
        canvas.drawLine(Offset(x, y), Offset(x - 2, y + length), rainPaint);
      }
    }

    // Ripples on "ground" (bottom of screen or random puddles)
    final ripplePaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    for (int i = 0; i < 6; i++) {
      final t = (progress + i / 6.0) % 1.0;
      final x = size.width * (0.1 + 0.8 * rng.nextDouble());
      final y = size.height * (0.3 + 0.6 * rng.nextDouble());
      final radius = 20 * t;
      final alpha = 0.3 * (1 - t);

      ripplePaint.color = spec.accent2.withValues(alpha: alpha);
      // Draw crushed oval for perspective explanation
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, y),
          width: radius * 3,
          height: radius,
        ),
        ripplePaint,
      );
    }
  }

  // ── Snow: Falling soft flakes ──
  void _drawRealisticSnow(Canvas canvas, Size size) {
    final snowPaint = Paint()..color = spec.accent;
    final rng = Random(404);

    final sprite = sprites?['assets/images/particles/snowflake.png'];

    for (int i = 0; i < 120; i++) {
      final xSeed = rng.nextDouble();
      final ySeed = rng.nextDouble();
      final sizeFactor = rng.nextDouble();

      final t = progress * (0.04 + 0.08 * sizeFactor);
      final yBase = (ySeed + t) % 1.1 * size.height - 10;
      final sway = sin(t * pi * 3 + i) * 18 * sizeFactor;
      final xBase = xSeed * size.width + sway;

      double x = xBase;
      double y = yBase;
      double alphaScale = 1.0;

      // ** Interaction: Snow blows away from touch **
      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 100) {
          final force = (100 - dist) / 100;
          x += (dx / dist) * force * 40;
          y += (dy / dist) * force * 40;
          alphaScale = 0.3 + 0.7 * (dist / 100);
        }
      }

      final radius = 1.0 + 3.0 * sizeFactor;
      final alpha = (0.3 + 0.7 * sizeFactor) * alphaScale;

      if (sprite != null) {
        final fSize = (2.0 + 6.0 * sizeFactor) * 2;
        final rotation = progress * pi * (0.1 + rng.nextDouble() * 0.2) + i;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(rotation);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(center: Offset.zero, width: fSize, height: fSize),
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
        canvas.restore();
      } else {
        snowPaint
          ..color = spec.accent.withValues(alpha: alpha)
          ..maskFilter =
              sizeFactor > 0.7
                  ? const MaskFilter.blur(BlurStyle.normal, 2)
                  : null;
        canvas.drawCircle(Offset(x, y), radius, snowPaint);
      }
    }
  }

  // ── Sunny: Bright sun + lens flare ──
  void _drawRealisticSunny(Canvas canvas, Size size) {
    final sunCenter = Offset(size.width * 0.85, size.height * 0.15);
    final sunRadius = size.shortestSide * 0.12;

    // Multi-ring sun glow
    for (int i = 0; i < 4; i++) {
      final r = sunRadius * (2.0 + i);
      final paint =
          Paint()
            ..shader = RadialGradient(
              colors: [spec.accent.withValues(alpha: 0.12), Colors.transparent],
            ).createShader(Rect.fromCircle(center: sunCenter, radius: r));
      canvas.drawCircle(sunCenter, r, paint);
    }

    // Sun core
    canvas.drawCircle(sunCenter, sunRadius, Paint()..color = spec.accent);
    canvas.drawCircle(
      sunCenter,
      sunRadius * 0.7,
      Paint()..color = Colors.white.withValues(alpha: 0.6),
    );

    // Animated rays
    final rayPaint =
        Paint()
          ..color = spec.accent.withValues(alpha: 0.15)
          ..strokeWidth = 2;
    for (int i = 0; i < 12; i++) {
      final angle = i * (pi * 2 / 12) + progress * 0.5;
      final p1 = Offset(
        sunCenter.dx + cos(angle) * sunRadius * 1.4,
        sunCenter.dy + sin(angle) * sunRadius * 1.4,
      );
      final p2 = Offset(
        sunCenter.dx + cos(angle) * sunRadius * 3.0,
        sunCenter.dy + sin(angle) * sunRadius * 3.0,
      );
      canvas.drawLine(p1, p2, rayPaint);
    }

    // Lens flare chase
    final centerScreen = Offset(size.width / 2, size.height / 2);
    final target = isPointerDown ? Offset(pointerX, pointerY) : centerScreen;

    final dir = target - sunCenter;
    final dist = dir.distance;
    final unit = dist > 0.1 ? dir / dist : Offset.zero;

    final flarePaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    void drawFlare(double percent, double r, Color c) {
      final pos = sunCenter + unit * (dist * percent);
      canvas.drawCircle(pos, r, flarePaint..color = c.withValues(alpha: 0.1));
    }

    drawFlare(0.3, 8 * (isPointerDown ? 1.5 : 1.0), spec.accent2);
    drawFlare(0.5, 25, spec.accent.withValues(alpha: 0.15));
    drawFlare(0.8, 4, Colors.white);
    drawFlare(1.1, 35 * (isPointerDown ? 1.2 : 1.0), spec.accent2);
  }

  // ── Aurora: waving light curtains ──
  void _drawRealisticAurora(Canvas canvas, Size size) {
    _drawAuroraCurtain(
      canvas,
      size,
      color: spec.accent.withValues(alpha: 0.25),
      heightFactor: 0.3,
      freq: 1.0,
      speed: 0.5,
      offset: 0,
    );
    _drawAuroraCurtain(
      canvas,
      size,
      color: spec.accent2.withValues(alpha: 0.20),
      heightFactor: 0.45,
      freq: 1.5,
      speed: 0.7,
      offset: 100,
    );
    // Stars in background
    _drawRealisticStars(canvas, size); // Reuse star painter
  }

  void _drawAuroraCurtain(
    Canvas canvas,
    Size size, {
    required Color color,
    required double heightFactor,
    required double freq,
    required double speed,
    required double offset,
  }) {
    final path = Path();
    final yBase = size.height * heightFactor;

    path.moveTo(0, size.height);
    path.lineTo(0, yBase);

    for (double x = 0; x <= size.width; x += 20) {
      double noise = _SimpleNoise.eval(
        x * 0.005 * freq + offset,
        progress * speed,
      );

      // ** Interaction: Plasma disturbance **
      if (isPointerDown) {
        final dist = (x - pointerX).abs();
        if (dist < 150) {
          final ripple = sin(dist * 0.05 - progress * 10) * (150 - dist) * 0.4;
          noise += ripple * 0.015;
        }
      }

      final y = yBase + noise * 60;
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.close();

    final paint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.0, 0.8],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(
      path,
      paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 25),
    );
  }

  // ── Storm: dark rolling clouds + lightning ──
  void _drawRealisticStorm(Canvas canvas, Size size) {
    // Rain (subtle)
    final rng = Random(123 + (progress * 100).toInt()); // Jittery rain
    final rainPaint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.05)
          ..strokeWidth = 1.0;

    for (int i = 0; i < 40; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      canvas.drawLine(Offset(x, y), Offset(x - 5, y + 15), rainPaint);
    }

    // Lightning
    // Use a hash of progress to act as a sporadic timer
    // We want a flash every ~3-5 seconds roughly.
    // Normalized progress 0..1 loops. Let's assume loop duration is 10s or similar.
    final flashVal = sin(progress * pi * 8) + sin(progress * pi * 23);
    final isFlash = flashVal > 1.8; // Rare spike

    if (isFlash) {
      // Screen flash
      canvas.drawRect(
        Offset.zero & size,
        Paint()..color = Colors.white.withValues(alpha: 0.1),
      );

      // Lightning bolt
      final boltPath = Path();
      // ** Interaction: Lightning Rod **
      double lx =
          isPointerDown
              ? pointerX + (rng.nextDouble() - 0.5) * 100
              : size.width * (0.2 + 0.6 * rng.nextDouble());
      double ly = 0;
      boltPath.moveTo(lx, ly);
      while (ly < size.height * 0.8) {
        lx += (rng.nextDouble() - 0.5) * 40;
        ly += 10 + rng.nextDouble() * 30;
        boltPath.lineTo(lx, ly);
      }
      final boltPaint =
          Paint()
            ..color = spec.accent2
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2
            ..maskFilter = const MaskFilter.blur(
              BlurStyle.solid,
              4,
            ); // Glowy bolt
      canvas.drawPath(boltPath, boltPaint);
    }

    // Clouds
    final cloudPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    for (int i = 0; i < 5; i++) {
      final cx = size.width * (0.2 * i + 0.1);
      final cy = size.height * 0.15;
      final drift = sin(progress * pi * 0.5 + i) * 20;
      cloudPaint.color = spec.accent.withValues(alpha: 0.3);
      canvas.drawCircle(Offset(cx + drift, cy), 80, cloudPaint);
    }
  }

  // ── Nebula: cosmic gas clouds ──
  void _drawRealisticNebula(Canvas canvas, Size size) {
    final gasPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);

    // Layer 1: Purple gas
    for (int i = 0; i < 4; i++) {
      final t = progress * 0.2 + i * 10;
      double x = size.width * (0.5 + 0.4 * _SimpleNoise.eval(t, 0));
      double y = size.height * (0.5 + 0.4 * _SimpleNoise.eval(0, t));

      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 300) {
          final s = (300 - dist) / 300;
          x += -dy / dist * s * 100;
          y += dx / dist * s * 100;
        }
      }

      gasPaint.color = spec.accent.withValues(alpha: 0.15);
      canvas.drawCircle(Offset(x, y), 120 + 40 * sin(t), gasPaint);
    }

    // Layer 2: Pink gas
    for (int i = 0; i < 4; i++) {
      final t = progress * 0.3 + i * 20 + 100;
      double x = size.width * (0.5 + 0.3 * _SimpleNoise.eval(t, 20));
      double y = size.height * (0.5 + 0.3 * _SimpleNoise.eval(20, t));

      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 300) {
          final s = (300 - dist) / 300;
          x += dy / dist * s * 80;
          y += -dx / dist * s * 80;
        }
      }

      gasPaint.color = spec.accent2.withValues(alpha: 0.12);
      canvas.drawCircle(Offset(x, y), 100 + 30 * cos(t), gasPaint);
    }

    // Stars overlay
    _drawRealisticStars(canvas, size);
  }

  // ── Nightmare: swirling dark fog ──
  void _drawRealisticFog(Canvas canvas, Size size) {
    final sprite = sprites?['assets/images/particles/smoke.png'];

    for (int i = 0; i < 12; i++) {
      final t = (progress * 0.4 + i / 12) % 1.0;
      double x = size.width * (0.5 + 0.5 * sin(t * pi * 2 + i));
      double y = size.height * (0.6 + 0.3 * cos(t * pi * 1.5 + i));

      // ** Interaction: Finger parting the smoke **
      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        final clearRadius = 250.0; // Radius to clear smoke

        if (dist < clearRadius && dist > 0.01) {
          // Push smoke heavily outwards, inverse to distance
          final pushForce = (clearRadius - dist) / clearRadius;
          // Scale affects how 'heavy' the puff feels
          x += (dx / dist) * pushForce * 150.0;
          y += (dy / dist) * pushForce * 150.0;
        }
      }

      final scale = 1.0 + t;
      final alpha = 0.05 * (1.0 - t).clamp(0, 1) + 0.02;

      if (sprite != null) {
        final drawW = size.width * 1.2 * scale;
        final drawH = size.height * 0.8 * scale;
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(t * 0.5);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(center: Offset.zero, width: drawW, height: drawH),
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
        canvas.restore();
      } else {
        final fogPaint =
            Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40);
        final radius = size.width * 0.4 + sin(t * pi) * 50;
        fogPaint.color = spec.accent.withValues(alpha: alpha);
        canvas.drawCircle(Offset(x, y), radius, fogPaint);
      }
    }
  }

  // ── Nightblue: twinkling stars ──
  void _drawRealisticStars(Canvas canvas, Size size) {
    final starPaint = Paint()..style = PaintingStyle.fill;
    final rng = Random(99);

    // Deep space nebula glow
    final glowPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60);
    glowPaint.color = spec.accent2.withValues(alpha: 0.08);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      150,
      glowPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.8),
      200,
      glowPaint,
    );

    // Stars
    final sprite = sprites?['assets/images/particles/star.png'];

    for (int i = 0; i < 100; i++) {
      double x = rng.nextDouble() * size.width;
      double y = rng.nextDouble() * size.height;
      final starSizeBase = rng.nextDouble() * 2.5 + 0.5;

      // Twinkle effect
      final twinkleSpeed = rng.nextDouble() * 5 + 2;
      double brightness =
          0.3 + 0.7 * sin(progress * twinkleSpeed + rng.nextDouble() * pi);

      // ** Interaction: Constellation Pulse **
      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 140) {
          final s = (140 - dist) / 140;
          brightness = (brightness + s).clamp(0, 1.2);
          // Stars nudge slightly towards finger
          x -= dx * s * 0.15;
          y -= dy * s * 0.15;
        }
      }

      if (sprite != null) {
        final drawSize =
            starSizeBase * (2.0 + (starSizeBase > 2.0 ? 2.0 : 0.0));
        canvas.save();
        canvas.translate(x, y);
        // Larger stars rotate slightly
        if (starSizeBase > 2.0) {
          canvas.rotate(progress * 0.1 + i);
        }
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset.zero,
            width: drawSize,
            height: drawSize,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: brightness.clamp(0, 1)),
        );
        canvas.restore();
      } else {
        starPaint.color = spec.accent.withValues(alpha: brightness);
        canvas.drawCircle(Offset(x, y), starSizeBase, starPaint);

        // Soft glow halo for brighter stars
        if (starSizeBase > 1.8) {
          final haloPaint =
              Paint()
                ..color = spec.accent.withValues(alpha: brightness * 0.15)
                ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(Offset(x, y), starSizeBase * 2.5, haloPaint);
        }
      }
    }

    // Shooting star (occasional)
    final shootingStarProgress = (progress * 0.3) % 1.0;
    if (shootingStarProgress > 0.85) {
      final t = (shootingStarProgress - 0.85) / 0.15;
      final sx = size.width * 0.8 - t * 200;
      final sy = size.height * 0.1 + t * 150;
      final tailPaint =
          Paint()
            ..strokeWidth = 2
            ..shader = LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0),
                Colors.white.withValues(alpha: 0.8),
              ],
            ).createShader(
              Rect.fromPoints(Offset(sx + 40, sy - 30), Offset(sx, sy)),
            );
      canvas.drawLine(Offset(sx + 40, sy - 30), Offset(sx, sy), tailPaint);
    }
  }

  // ── Dark Nature: fireflies ──
  void _drawRealisticFireflies(Canvas canvas, Size size) {
    final glowPaint =
        Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final corePaint = Paint()..style = PaintingStyle.fill;

    final rng = Random(77);
    final sprite = sprites?['assets/images/particles/firefly.png'];

    for (int i = 0; i < 15; i++) {
      // Organic movement path
      final t = (progress + i / 15.0) % 1.0;
      final seedX = rng.nextDouble();
      final seedY = rng.nextDouble();

      // Lissajous curve movement
      double x = size.width * (seedX + 0.1 * sin(t * pi * 4 + i));
      double y = size.height * (seedY + 0.1 * cos(t * pi * 3 + i));

      // ** Interaction: Fireflies flee from finger! **
      if (isPointerDown) {
        final dx = x - pointerX;
        final dy = y - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        final runRadius = 150.0; // Distance at which they start fleeing

        if (dist < runRadius && dist > 0.01) {
          // Push them away, inversely proportional to distance
          final pushForce = (runRadius - dist) / runRadius;
          x += (dx / dist) * pushForce * 80.0;
          y += (dy / dist) * pushForce * 80.0;
        }
      }

      // Pulse
      final pulse = 0.5 + 0.5 * sin(t * pi * 8 + i);

      if (sprite != null) {
        final fSize = 12.0 + 8.0 * pulse;
        canvas.save();
        canvas.translate(x, y);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(center: Offset.zero, width: fSize, height: fSize),
          Paint()..color = Colors.white.withValues(alpha: (0.4 + 0.6 * pulse)),
        );
        canvas.restore();
      } else {
        // Glow
        glowPaint.color = spec.accent2.withValues(alpha: 0.15 * pulse);
        canvas.drawCircle(Offset(x, y), 6 + 4 * pulse, glowPaint);

        // Core
        corePaint.color = spec.accent2.withValues(alpha: 0.6 + 0.4 * pulse);
        canvas.drawCircle(Offset(x, y), 1.5, corePaint);
      }
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
        double y1 = sin((x / size.width) * pi * freq + phase) * amplitude;
        final y2 =
            sin((x / size.width) * pi * (freq * 1.3) + phase * 0.7) *
            amplitude *
            0.4;

        // ** Interaction: Ripple Engine **
        if (isPointerDown) {
          final dist = (x - pointerX).abs();
          if (dist < 120) {
            final rip = sin(dist * 0.1 - progress * 15) * (120 - dist) * 0.25;
            y1 += rip;
          }
        }

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
      foamPath.moveTo(0, baseY - 2);
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
    final spriteGreen = sprites?['assets/images/particles/leaf_green.png'];
    final spriteOrange = sprites?['assets/images/particles/leaf_autumn.png'];

    for (int i = 0; i < 30; i++) {
      final x = rng.nextDouble();
      final y = rng.nextDouble();
      final speed = ui.lerpDouble(0.015, 0.05, rng.nextDouble())!;
      final sway = sin(progress * pi * 2 * (0.5 + rng.nextDouble()) + i) * 0.03;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final dx = x + sway;
      final leafSize = ui.lerpDouble(12, 28, rng.nextDouble())!;

      // Calculate screen positions
      double screenX = dx * size.width;
      double screenY = dy * size.height;
      double angle = progress * pi * 2 * (0.2 + rng.nextDouble() * 0.3);

      // ** Interaction: Leaves swirl around the finger! **
      if (isPointerDown) {
        final pdx = screenX - pointerX;
        final pdy = screenY - pointerY;
        final dist = sqrt(pdx * pdx + pdy * pdy);
        final affectRadius = 200.0;

        if (dist < affectRadius && dist > 0.01) {
          final force = (affectRadius - dist) / affectRadius;
          // Add outward push + a tangential swirl force
          final pushX = (pdx / dist);
          final pushY = (pdy / dist);
          final swirlX = -pushY; // Tangent X
          // Mix them
          screenX += (pushX * 50.0 + swirlX * 100.0) * force;
          screenY += (pushY * 50.0) * force;

          // Spin them rapidly when hit
          angle += force * 4.0;
        }
      }

      final sprite = i.isEven ? spriteGreen : spriteOrange;

      if (sprite != null) {
        canvas.save();
        canvas.translate(screenX, screenY);
        canvas.rotate(angle);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset.zero,
            width: leafSize,
            height: leafSize,
          ),
          Paint()..color = Colors.white.withValues(alpha: 0.9),
        );
        canvas.restore();
      } else {
        // Multi-toned leaf color
        final leafColor =
            i.isEven
                ? spec.accent.withValues(alpha: 0.14 + rng.nextDouble() * 0.06)
                : spec.accent2.withValues(
                  alpha: 0.12 + rng.nextDouble() * 0.06,
                );
        _paintRealisticLeaf(
          canvas,
          Offset(screenX, screenY),
          leafSize,
          angle,
          leafColor,
        );
      }
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
    final sprite = sprites?['assets/images/particles/petal.png'];

    for (int i = 0; i < 40; i++) {
      final x = petalRng.nextDouble();
      final y = petalRng.nextDouble();
      final speed = ui.lerpDouble(0.02, 0.06, petalRng.nextDouble())!;
      final sway =
          sin(progress * pi * 2 * (0.6 + petalRng.nextDouble()) + i) * 0.025;
      final dy = (y + progress * speed) % 1.2 - 0.1;
      final dx = x + sway;
      final petalSize = ui.lerpDouble(8, 20, petalRng.nextDouble())!;

      double screenX = dx * size.width;
      double screenY = dy * size.height;
      double angle = progress * pi * 2 * (0.3 + petalRng.nextDouble() * 0.4);
      final alpha = 0.15 + petalRng.nextDouble() * 0.15;

      // ** Interaction: Spring blossoms swirl! **
      if (isPointerDown) {
        final pdx = screenX - pointerX;
        final pdy = screenY - pointerY;
        final dist = sqrt(pdx * pdx + pdy * pdy);
        final affectRadius = 160.0;

        if (dist < affectRadius && dist > 0.01) {
          final force = (affectRadius - dist) / affectRadius;
          final pushX = (pdx / dist);
          final pushY = (pdy / dist);
          final swirlX = -pushY;
          final swirlY = pushX;

          // Petals are lighter than leaves, so they swirl more aggressively
          screenX += (pushX * 30.0 + swirlX * 120.0) * force;
          screenY += (pushY * 30.0 + swirlY * 40.0) * force;
          angle += force * 5.0;
        }
      }

      if (sprite != null) {
        canvas.save();
        canvas.translate(screenX, screenY);
        canvas.rotate(angle);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset.zero,
            width: petalSize,
            height: petalSize,
          ),
          Paint()
            ..color = Colors.white.withValues(
              alpha: (alpha * 6.0).clamp(0.0, 1.0),
            ),
        );
        canvas.restore();
      } else {
        _paintCherryPetal(
          canvas,
          Offset(screenX, screenY),
          petalSize,
          angle,
          spec.accent.withValues(alpha: alpha),
        );
      }
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
    final sprite = sprites?['assets/images/particles/heart.png'];

    for (int i = 0; i < 24; i++) {
      final x = heartRng.nextDouble();
      final y = heartRng.nextDouble();
      final speed = ui.lerpDouble(0.02, 0.08, heartRng.nextDouble())!;
      final drift = heartRng.nextDouble();
      final dy = (y - progress * speed + 1.2) % 1.2 - 0.1;
      final dx = x + sin((progress + drift) * pi * 2) * 0.02;
      final sizeFactor = ui.lerpDouble(8, 20, heartRng.nextDouble())!;

      double screenX = dx * size.width;
      double screenY = dy * size.height;
      double alpha = 0.06 + heartRng.nextDouble() * 0.10;

      // ** Interaction: Affection Attraction **
      if (isPointerDown) {
        final pdx = screenX - pointerX;
        final pdy = screenY - pointerY;
        final dist = sqrt(pdx * pdx + pdy * pdy);
        if (dist < 200) {
          final s = (200 - dist) / 200;
          // Drift towards finger
          screenX -= pdx * s * 0.3;
          screenY -= pdy * s * 0.3;
          alpha = (alpha + s * 0.2).clamp(0, 1);
        }
      }

      final center = Offset(screenX, screenY);

      if (sprite != null) {
        final drawSize = sizeFactor * 2.2;
        final angle = sin(progress * pi + i) * 0.2;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(angle);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(
            center: Offset.zero,
            width: drawSize,
            height: drawSize,
          ),
          Paint()
            ..color = Colors.white.withValues(alpha: (alpha * 5.0).clamp(0, 1)),
        );
        canvas.restore();
      } else {
        // Heart with glow halo fallback
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
      final path = Path();
      path.moveTo(x, 0);
      for (double y = 0; y <= size.height; y += 10) {
        double dx = x;
        if (isPointerDown) {
          final pdx = dx - pointerX;
          final pdy = y - pointerY;
          final dist = sqrt(pdx * pdx + pdy * pdy);
          if (dist < 150) {
            final s = (150 - dist) / 150;
            dx += pdx * s * 0.4; // Magnetic push
          }
        }
        path.lineTo(dx, y);
      }
      canvas.drawPath(path, gridPaint);
    }
    for (double y = 0; y <= size.height; y += step) {
      final path = Path();
      path.moveTo(0, y);
      for (double x = 0; x <= size.width; x += 10) {
        double dy = y;
        if (isPointerDown) {
          final pdx = x - pointerX;
          final pdy = dy - pointerY;
          final dist = sqrt(pdx * pdx + pdy * pdy);
          if (dist < 150) {
            final s = (150 - dist) / 150;
            dy += pdy * s * 0.4;
          }
        }
        path.lineTo(x, dy);
      }
      canvas.drawPath(path, gridPaint);
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
    final sprite = sprites?['assets/images/particles/bubble.png'];

    for (int i = 0; i < 24; i++) {
      final x = rng.nextDouble() * size.width;
      final rawY = rng.nextDouble();
      final y =
          ((rawY + progress * 0.06) % 1.1) * size.height - size.height * 0.05;
      final radius = ui.lerpDouble(14, 38, rng.nextDouble())!;
      double screenX = x;
      double screenY = y;

      // ** Interaction: Bubble Push **
      if (isPointerDown) {
        final dx = screenX - pointerX;
        final dy = screenY - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        if (dist < 120) {
          final s = (120 - dist) / 120;
          screenX += dx / dist * s * 60;
          screenY += dy / dist * s * 60;
        }
      }
      final center = Offset(screenX, screenY);

      if (sprite != null) {
        final bSize = radius * 2.5;
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(progress * 0.2 + i);
        canvas.drawImageRect(
          sprite,
          Rect.fromLTWH(
            0,
            0,
            sprite.width.toDouble(),
            sprite.height.toDouble(),
          ),
          Rect.fromCenter(center: Offset.zero, width: bSize, height: bSize),
          Paint()..color = Colors.white.withValues(alpha: 0.8),
        );
        canvas.restore();
      } else {
        // Bubble body fallback
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
      }
    }
  }

  // ── Procedural swaying plants (grass, herbs) ──
  void _drawSwayingPlants(Canvas canvas, Size size) {
    final rng = Random(12345);
    final count = 45;
    final windSway = sin(progress * pi * 4) * 0.15;

    // ** Extra Materials: Wet Stones/Mud for Rain Theme **
    final isRain = spec.motif == _PaperMotif.raining;
    if (isRain) {
      final stonePaint = Paint()..color = Colors.black.withValues(alpha: 0.15);
      final stoneRng = Random(88);
      for (int i = 0; i < 12; i++) {
        final sx = stoneRng.nextDouble() * size.width;
        final sw = 40.0 + stoneRng.nextDouble() * 80.0;
        final sh = 10.0 + stoneRng.nextDouble() * 15.0;
        canvas.drawOval(
          Rect.fromLTWH(sx, size.height - sh * 0.5, sw, sh),
          stonePaint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
        );
      }
    }

    for (int i = 0; i < count; i++) {
      final x = (i / count) * size.width + (rng.nextDouble() * 20 - 10);
      double h = 15.0 + rng.nextDouble() * 35.0;

      // Rain theme has lush, larger grass
      if (isRain) {
        h *= 1.6;
      }

      final color = Color.lerp(
        spec.accent,
        spec.accent2,
        rng.nextDouble() * 0.5,
      )!.withValues(alpha: 0.12 + rng.nextDouble() * 0.08);

      final paint =
          Paint()
            ..color = color
            ..style = PaintingStyle.stroke
            ..strokeWidth =
                (1.0 + rng.nextDouble() * 2.0) * (isRain ? 1.5 : 1.0)
            ..strokeCap = StrokeCap.round;

      final path = Path();
      path.moveTo(x, size.height + 5);

      // Base wind bending
      double swayVal = windSway;

      // ** Interaction: Physical touch forces grass to bend! **
      if (isPointerDown) {
        // Approximate top of the blade location before bending
        final bladeTopY = size.height - h;
        final dx = x - pointerX;
        final dy = bladeTopY - pointerY;
        final dist = sqrt(dx * dx + dy * dy);
        final affectRadius = 100.0 * (isRain ? 1.4 : 1.0);

        if (dist < affectRadius && dist > 0.01) {
          // Push away violently from the finger
          final pushForce = (affectRadius - dist) / affectRadius;
          final swayDirection = dx > 0 ? 1.0 : -1.0;

          // Bend is much stronger than wind
          swayVal += swayDirection * pushForce * 1.5;
        }
      }

      // Quadratic curve to simulate bending blade
      final controlX = x + (swayVal * h * 1.5);
      final controlY = size.height - h * 0.5;
      final endX = x + (swayVal * h * 3.0);
      final endY = size.height - h;

      path.quadraticBezierTo(controlX, controlY, endX, endY);
      canvas.drawPath(path, paint);

      // Occasional "herb" or "flower" head
      if (i % 7 == 0) {
        final headPaint =
            Paint()..color = color.withValues(alpha: color.a * 1.5);
        canvas.drawCircle(Offset(endX, endY), isRain ? 3 : 2, headPaint);
      }
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
    Color color, {
    double? blur,
  }) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final paint = Paint()..color = color;
    if (blur != null) {
      paint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur);
    }

    // Leaf body
    final body =
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(size * 0.5, -size * 0.9, size * 1.1, 0)
          ..quadraticBezierTo(size * 0.5, size * 0.9, 0, 0);
    canvas.drawPath(body, paint);

    // Center vein
    final veinPaint =
        Paint()
          ..color = color.withValues(alpha: (color.a * 1.4).clamp(0.0, 1.0))
          ..strokeWidth = 0.6;
    if (blur != null) {
      veinPaint.maskFilter = MaskFilter.blur(BlurStyle.normal, blur * 0.5);
    }

    canvas.drawLine(Offset.zero, Offset(size * 1.1, 0), veinPaint);
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
    return oldDelegate.progress != progress ||
        oldDelegate.spec != spec ||
        oldDelegate.pointerX != pointerX ||
        oldDelegate.pointerY != pointerY ||
        oldDelegate.isPointerDown != isPointerDown;
  }
}

class _SimpleNoise {
  // Simple pseudo-noise using sin summation
  static double eval(double x, double y) {
    return sin(x) + sin(y) * 0.5 + sin(x * 2.1 + y * 1.4) * 0.25;
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
