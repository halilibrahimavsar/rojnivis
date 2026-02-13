import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';

class BookOpeningAnimation extends StatefulWidget {
  const BookOpeningAnimation({super.key, required this.onAnimationComplete});

  final VoidCallback onAnimationComplete;

  @override
  State<BookOpeningAnimation> createState() => _BookOpeningAnimationState();
}

class _BookOpeningAnimationState extends State<BookOpeningAnimation>
    with TickerProviderStateMixin {
  late final AnimationController _bookOpenController;
  late final AnimationController _writingController;
  late final AnimationController _ambientController;
  late final Ticker _penPhysicsTicker;

  late final Path _signaturePath;
  late final List<PathMetric> _signatureMetrics;
  late final Rect _signatureBounds;
  late final double _totalSignatureLength;

  Offset _penPosition = Offset.zero;
  Offset _penVelocity = Offset.zero;
  double _penAngle = -0.45;
  Duration? _lastPhysicsTick;
  bool _didComplete = false;

  @override
  void initState() {
    super.initState();

    _signaturePath = _buildRojnivisPath();
    _signatureMetrics = _signaturePath.computeMetrics().toList();
    _totalSignatureLength = _signatureMetrics.fold(
      0.0,
      (sum, metric) => sum + metric.length,
    );
    _signatureBounds = _signaturePath.getBounds();
    final firstMetric =
        _signatureMetrics.isNotEmpty ? _signatureMetrics.first : null;
    _penPosition =
        firstMetric?.getTangentForOffset(0.0)?.position ??
        const Offset(0.05, 0.74);

    _bookOpenController = AnimationController.unbounded(vsync: this);
    _writingController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 2800,
      ), // Slightly slower for clarity
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _penPhysicsTicker = createTicker(_tickPenPhysics);
    _runSequence();
  }

  Future<void> _runSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // Stiffer spring for a "heavier" book feel
    const bookSpring = SpringDescription(
      mass: 1.0,
      stiffness: 140.0,
      damping: 18.0,
    );
    final openSimulation = SpringSimulation(
      bookSpring,
      0.0,
      1.0,
      0.0,
      tolerance: const Tolerance(velocity: 0.0001, distance: 0.0001),
    );

    await _bookOpenController.animateWith(openSimulation);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    _lastPhysicsTick = null;
    _penPhysicsTicker.start();
    await _writingController.forward(from: 0.0);
    if (!mounted) return;

    await Future.delayed(const Duration(milliseconds: 800));
    if (_penPhysicsTicker.isActive) {
      _penPhysicsTicker.stop();
    }

    if (!_didComplete) {
      _didComplete = true;
      widget.onAnimationComplete();
    }
  }

  void _tickPenPhysics(Duration elapsed) {
    if (!mounted) return;

    final previousTick = _lastPhysicsTick;
    _lastPhysicsTick = elapsed;
    final dtSeconds =
        previousTick == null
            ? (1.0 / 60.0)
            : (elapsed - previousTick).inMicroseconds / 1000000.0;
    final dt = dtSeconds.clamp(1.0 / 240.0, 1.0 / 30.0);

    final progress = _handwritingProgress(_writingController.value);
    final sample = _sampleSignature(progress);
    final target = sample.position;
    final tangent = sample.tangent;

    // Physics tuning for the pen
    const stiffness = 120.0;
    const damping = 22.0;
    final displacement = target - _penPosition;
    final acceleration = displacement * stiffness - _penVelocity * damping;

    _penVelocity += acceleration * dt;
    _penVelocity *= 0.96; // Drag
    _penPosition += _penVelocity * dt;

    final desiredAngle = math.atan2(
      tangent.dy + (_penVelocity.dy * 0.1),
      tangent.dx + (_penVelocity.dx * 0.1),
    );
    final delta = _normalizeAngle(desiredAngle - _penAngle);
    _penAngle += delta * (1 - math.exp(-15.0 * dt));

    if (_writingController.isCompleted) {
      _penPosition += (target - _penPosition) * 0.2;
      _penVelocity *= 0.8;
    }

    setState(() {});
  }

  _SignatureSample _sampleSignature(double progress) {
    if (_signatureMetrics.isEmpty || _totalSignatureLength <= 0.0) {
      return const _SignatureSample(
        position: Offset(0.05, 0.74),
        tangent: Offset(1.0, 0.0),
      );
    }

    final clamped = progress.clamp(0.0, 1.0);
    final targetDistance = _totalSignatureLength * clamped;

    var traversed = 0.0;
    for (final metric in _signatureMetrics) {
      final next = traversed + metric.length;
      if (targetDistance <= next) {
        final localDistance = (targetDistance - traversed).clamp(
          0.0,
          metric.length,
        );
        final tangent = metric.getTangentForOffset(localDistance);
        if (tangent != null) {
          return _SignatureSample(
            position: tangent.position,
            tangent: tangent.vector,
          );
        }
        break;
      }
      traversed = next;
    }

    final last = _signatureMetrics.last;
    final lastTangent = last.getTangentForOffset(last.length);
    if (lastTangent != null) {
      return _SignatureSample(
        position: lastTangent.position,
        tangent: lastTangent.vector,
      );
    }

    return _SignatureSample(
      position: _penPosition,
      tangent: const Offset(1.0, 0.0),
    );
  }

  double _handwritingProgress(double t) {
    // Smoother curve for clearer writing flow
    final eased = Curves.easeInOutCubic.transform(t.clamp(0.0, 1.0));
    return eased;
  }

  double _normalizeAngle(double angle) {
    var normalized = angle;
    while (normalized > math.pi) {
      normalized -= 2 * math.pi;
    }
    while (normalized < -math.pi) {
      normalized += 2 * math.pi;
    }
    return normalized;
  }

  @override
  void dispose() {
    _penPhysicsTicker.dispose();
    _bookOpenController.dispose();
    _writingController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final viewportSize = MediaQuery.sizeOf(context);
    final expandedSize = Size(
      viewportSize.width + viewPadding.horizontal,
      viewportSize.height + viewPadding.vertical,
    );

    return Transform.translate(
      offset: Offset(-viewPadding.left, -viewPadding.top),
      child: SizedBox(
        width: expandedSize.width,
        height: expandedSize.height,
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _bookOpenController,
            _writingController,
            _ambientController,
          ]),
          builder: (context, child) {
            final rawOpen = _bookOpenController.value;
            final openProgress = rawOpen.clamp(0.0, 1.0);
            final writingProgress = _handwritingProgress(
              _writingController.value,
            );
            final ambientTime = _ambientController.value;

            return Stack(
              fit: StackFit.expand,
              children: [
                CustomPaint(
                  painter: _SplashBackgroundPainter(
                    openProgress: openProgress,
                    ambientTime: ambientTime,
                  ),
                ),
                Align(
                  alignment: const Alignment(0, 0.1),
                  child: _BookScene(
                    sceneSize: expandedSize,
                    signaturePath: _signaturePath,
                    signatureBounds: _signatureBounds,
                    openProgress: openProgress,
                    rawOpenProgress: rawOpen,
                    writingProgress: writingProgress,
                    penPosition: _penPosition,
                    penAngle: _penAngle,
                    ambientTime: ambientTime,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _BookScene extends StatelessWidget {
  const _BookScene({
    required this.sceneSize,
    required this.signaturePath,
    required this.signatureBounds,
    required this.openProgress,
    required this.rawOpenProgress,
    required this.writingProgress,
    required this.penPosition,
    required this.penAngle,
    required this.ambientTime,
  });

  final Size sceneSize;
  final Path signaturePath;
  final Rect signatureBounds;
  final double openProgress;
  final double rawOpenProgress;
  final double writingProgress;
  final Offset penPosition;
  final double penAngle;
  final double ambientTime;

  @override
  Widget build(BuildContext context) {
    final easedOpen = Curves.easeOutQuart.transform(openProgress);
    final openTail = (rawOpenProgress - 1.0).clamp(-0.15, 0.15);

    // Scale book relative to screen
    final bookWidth = math.min(sceneSize.width * 0.90, 980.0);
    final bookHeight = math.min(sceneSize.height * 0.55, 600.0);
    final spineWidth = math.max(12.0, bookWidth * 0.025);

    // Open cover animation
    final coverAngle = (-math.pi * 0.85 * easedOpen) + (openTail * 0.10);
    final coverFlutter =
        math.sin(ambientTime * math.pi * 6.0) * (1.0 - easedOpen) * 0.02;
    final showWriting = writingProgress > 0.001;

    // The "Text Block" (pages thickness) needs to slide out as book opens
    final pageBlockOffset = 4.0 + (10.0 * easedOpen);

    const coverDark = Color(0xFF2A1406);
    const coverMid = Color(0xFF5C3317);
    const coverLight = Color(0xFF8B5A2B);

    return SizedBox(
      width: bookWidth,
      height: bookHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Back Cover Shadow (Environment)
          Positioned(
            left: bookWidth * 0.05,
            right: bookWidth * 0.05,
            bottom: -bookHeight * 0.04,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(50),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 60,
                    spreadRadius: -10,
                  ),
                ],
              ),
              child: SizedBox(height: bookHeight * 0.05),
            ),
          ),

          // 2. Back Cover (The hard board)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomRight: Radius.circular(8),
                  topLeft: Radius.circular(4),
                  bottomLeft: Radius.circular(4),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [coverDark, coverMid, coverLight],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 15,
                    offset: const Offset(4, 8),
                  ),
                ],
              ),
            ),
          ),

          // 3. The Page Block (The thickness of the pages on the right)
          Positioned(
            top: 6,
            bottom: 6,
            left: spineWidth,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE0D0B0), // Aged paper side color
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(4),
                  bottomRight: Radius.circular(4),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  stops: const [0.0, 0.1, 0.9, 1.0],
                  colors: [
                    const Color(0xFFC0B090),
                    const Color(0xFFE8DCCA),
                    const Color(0xFFE8DCCA),
                    const Color(0xFFD0C0A0),
                  ],
                ),
                boxShadow: [
                  // Subtle shadow to show thickness
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    offset: Offset(-1, 1),
                    blurRadius: 1,
                  ),
                ],
              ),
              child: CustomPaint(painter: _PageBlockTexturePainter()),
            ),
          ),

          // 4. The Top Pages (Left and Right open pages)
          Positioned(
            top: pageBlockOffset,
            bottom: pageBlockOffset,
            left: spineWidth + 2,
            right: pageBlockOffset + 2,
            child: Row(
              children: [
                // Left Page (glued to spine/cover mostly, mostly hidden by cover rotation in real life but we draw flat)
                Expanded(
                  child: _PaperSheet(
                    isLeft: true,
                    child: const CustomPaint(
                      painter: _PaperTexturePainter(drawGuides: false),
                    ),
                  ),
                ),
                // Center Binding/Gutter
                Container(
                  width: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
                // Right Page (Where we write)
                Expanded(
                  child: _PaperSheet(
                    isLeft: false,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        const CustomPaint(
                          painter: _PaperTexturePainter(drawGuides: true),
                        ),
                        // The Handwriting Layer
                        CustomPaint(
                          painter: _WritingPainter(
                            signaturePath: signaturePath,
                            signatureBounds: signatureBounds,
                            writingProgress: writingProgress,
                            penPosition: penPosition,
                            penAngle: penAngle,
                            showPen: showWriting,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 5. Spine Shadow Overlay (The deep crease)
          Positioned(
            top: 0,
            bottom: 0,
            left: spineWidth,
            width: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // 6. The Front Cover (Animated)
          Positioned.fill(
            child: Transform(
              alignment: Alignment.centerLeft,
              transform:
                  Matrix4.identity()
                    ..setEntry(3, 2, 0.0015) // Perspective
                    ..rotateY(coverAngle + coverFlutter),
              child: _FrontCover(
                width: bookWidth,
                height: bookHeight,
                easedOpen: easedOpen,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaperSheet extends StatelessWidget {
  final Widget child;
  final bool isLeft;
  const _PaperSheet({required this.child, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    const paperLight = Color(0xFFF4EAD5); // Slightly warmer/older
    const paperDark = Color(0xFFE6D6B8);

    return ClipRRect(
      borderRadius: BorderRadius.only(
        topRight: isLeft ? Radius.zero : const Radius.circular(6),
        bottomRight: isLeft ? Radius.zero : const Radius.circular(6),
        topLeft: isLeft ? const Radius.circular(6) : Radius.zero,
        bottomLeft: isLeft ? const Radius.circular(6) : Radius.zero,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: paperLight,
          gradient: LinearGradient(
            begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            stops: const [0.0, 0.08, 1.0],
            colors: [
              const Color(0xFFD9C6A5), // Darker at gutter
              paperLight,
              paperDark,
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

class _FrontCover extends StatelessWidget {
  final double width;
  final double height;
  final double easedOpen;

  const _FrontCover({
    required this.width,
    required this.height,
    required this.easedOpen,
  });

  @override
  Widget build(BuildContext context) {
    const coverDark = Color(0xFF2A1406);
    const coverMid = Color(0xFF6A3814);
    const coverLight = Color(0xFF9A5B25);

    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(12),
          bottomRight: Radius.circular(12),
          topLeft: Radius.circular(4),
          bottomLeft: Radius.circular(4),
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [coverLight, coverMid, coverDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Texture overlay
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(painter: _PageBlockTexturePainter()),
            ),
          ),
          Center(
            child: Container(
              width: width * 0.6,
              height: height * 0.75,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(
                    0xFFD4AF37,
                  ).withValues(alpha: 0.4), // Gold leaf
                  width: 2,
                ),
              ),
              child: Center(
                child: Opacity(
                  opacity: (1 - (easedOpen * 1.5)).clamp(0.0, 1.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_stories,
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
                        size: 40,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'ROJNIVIS',
                        style: GoogleFonts.cinzel(
                          fontSize: width * 0.07,
                          letterSpacing: 3.0,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFD4AF37).withValues(alpha: 0.8),
                          shadows: [
                            Shadow(
                              blurRadius: 2,
                              color: Colors.black.withValues(alpha: 0.5),
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackgroundPainter extends CustomPainter {
  const _SplashBackgroundPainter({
    required this.openProgress,
    required this.ambientTime,
  });

  final double openProgress;
  final double ambientTime;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    // Richer background gradient
    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(
          const Color(0xFF151922),
          const Color(0xFF1F1A15),
          openProgress,
        )!,
        Color.lerp(
          const Color(0xFF0F1218),
          const Color(0xFF2E2219),
          openProgress,
        )!,
        const Color(0xFF050709),
      ],
    );
    canvas.drawRect(rect, Paint()..shader = gradient.createShader(rect));

    // Warm desk lamp glow
    final glowCenter = Offset(size.width * 0.5, size.height * 0.5);
    final glowRadius = size.longestSide * 0.6;
    canvas.drawCircle(
      glowCenter,
      glowRadius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(
              0xFFFFCC99,
            ).withValues(alpha: 0.08 + (openProgress * 0.08)),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glowCenter, radius: glowRadius)),
    );

    // Dust motes
    final particlePaint = Paint();
    final drift = ambientTime * math.pi * 2.0;
    for (var i = 0; i < 30; i++) {
      final seed = i + 1;
      final px = _rand(seed * 13, 0.31) * size.width;
      final py = _rand(seed * 29, 1.87) * size.height;
      final dx =
          math.sin(drift + (seed * 0.73)) * (10 + _rand(seed, 2.41) * 10);
      final dy =
          math.cos((drift * 0.8) + (seed * 0.61)) * (5 + _rand(seed, 3.11) * 5);
      final alpha = 0.04 + (_rand(seed, 4.19) * 0.1) + (openProgress * 0.02);
      final radius = 1.0 + _rand(seed, 5.93) * 2.0;

      particlePaint.color = Colors.white.withValues(
        alpha: alpha.clamp(0.0, 0.15),
      );
      canvas.drawCircle(Offset(px + dx, py + dy), radius, particlePaint);
    }
  }

  double _rand(int seed, double shift) {
    final value = math.sin((seed * 12.9898) + shift) * 43758.5453;
    return value - value.floorToDouble();
  }

  @override
  bool shouldRepaint(covariant _SplashBackgroundPainter oldDelegate) {
    return oldDelegate.openProgress != openProgress ||
        oldDelegate.ambientTime != ambientTime;
  }
}

class _PageBlockTexturePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.black.withValues(alpha: 0.05)
          ..strokeWidth = 0.5;

    // Draw horizontal lines to simulate stacked pages
    for (double i = 1; i < size.height; i += 2) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _PaperTexturePainter extends CustomPainter {
  const _PaperTexturePainter({required this.drawGuides});

  final bool drawGuides;

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Paper Grain (Noise)
    final grainPaint =
        Paint()
          ..color = const Color(0xFF8B7355).withValues(alpha: 0.08)
          ..strokeWidth = 1.2
          ..style = PaintingStyle.stroke;

    final r = math.Random(42);
    for (var i = 0; i < 200; i++) {
      final x = r.nextDouble() * size.width;
      final y = r.nextDouble() * size.height;
      canvas.drawCircle(Offset(x, y), 0.5, grainPaint);
    }

    if (!drawGuides) return;

    // 2. Ruled Lines (Faded blueish ink)
    final linePaint =
        Paint()
          ..color = const Color(0xFF6A7EA8).withValues(alpha: 0.12)
          ..strokeWidth = 1.5;
    final spacing = size.height / 10;

    // Header line (Pinkish red standard in notebooks)
    final headerPaint =
        Paint()
          ..color = const Color(0xFFA86A6A).withValues(alpha: 0.12)
          ..strokeWidth = 1.5;

    canvas.drawLine(
      Offset(0, spacing * 1.5),
      Offset(size.width, spacing * 1.5),
      headerPaint,
    );

    for (var i = 3; i < 10; i++) {
      final y = i * spacing;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PaperTexturePainter oldDelegate) {
    return oldDelegate.drawGuides != drawGuides;
  }
}

class _WritingPainter extends CustomPainter {
  const _WritingPainter({
    required this.signaturePath,
    required this.signatureBounds,
    required this.writingProgress,
    required this.penPosition,
    required this.penAngle,
    required this.showPen,
  });

  final Path signaturePath;
  final Rect signatureBounds;
  final double writingProgress;
  final Offset penPosition;
  final double penAngle;
  final bool showPen;

  @override
  void paint(Canvas canvas, Size size) {
    // Define area for text to live
    final textRect = Rect.fromLTWH(
      size.width * 0.15,
      size.height * 0.35,
      size.width * 0.7,
      size.height * 0.4,
    );

    // Draw Ghost/Watermark Text (optional, subtle guide)
    // Removed for "clearer" request - keeping focus on the ink.

    final fittedPath = _fitPathIntoRect(
      signaturePath,
      signatureBounds,
      textRect,
    );
    final drawnPath = _extractPathByProgress(fittedPath, writingProgress);

    // 1. Ink Bleed (Subtle blur behind)
    canvas.drawPath(
      drawnPath,
      Paint()
        ..color = const Color(0xFF0F1520).withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
    );

    // 2. Main Ink Stroke (Dark Navy/Black)
    final inkStroke =
        Paint()
          ..color = const Color(0xFF181C26) // Deep fountain pen blue-black
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..strokeWidth = 3.5;

    canvas.drawPath(drawnPath, inkStroke);

    // 3. Wet Ink Highlight (Specular reflection on the fresh ink)
    // Only draw at the very end of the current path to simulate wetness
    if (writingProgress > 0 && writingProgress < 0.99) {
      final metrics = drawnPath.computeMetrics().toList();
      if (metrics.isNotEmpty) {
        final lastMetric = metrics.last;
        final tan = lastMetric.getTangentForOffset(lastMetric.length);
        if (tan != null) {
          canvas.drawCircle(
            tan.position,
            2.0,
            Paint()..color = Colors.white.withValues(alpha: 0.3),
          );
        }
      }
    }

    if (!showPen) return;

    final mappedPen = _mapPointToRect(penPosition, signatureBounds, textRect);
    _drawPen(canvas, mappedPen, penAngle, size.shortestSide);
  }

  Path _fitPathIntoRect(Path source, Rect sourceBounds, Rect targetRect) {
    // Maintain aspect ratio but fit nicely
    final scale = math.min(
      targetRect.width / sourceBounds.width,
      targetRect.height / sourceBounds.height,
    );

    // Center it
    final dx =
        targetRect.left +
        ((targetRect.width - (sourceBounds.width * scale)) * 0.5) -
        (sourceBounds.left * scale);
    final dy =
        targetRect.top +
        ((targetRect.height - (sourceBounds.height * scale)) * 0.5) -
        (sourceBounds.top * scale);

    return source.transform(
      (Matrix4.identity()
            ..translate(dx, dy)
            ..scale(scale, scale))
          .storage,
    );
  }

  Offset _mapPointToRect(Offset point, Rect sourceBounds, Rect targetRect) {
    final scale = math.min(
      targetRect.width / sourceBounds.width,
      targetRect.height / sourceBounds.height,
    );
    final dx =
        targetRect.left +
        ((targetRect.width - (sourceBounds.width * scale)) * 0.5) -
        (sourceBounds.left * scale);
    final dy =
        targetRect.top +
        ((targetRect.height - (sourceBounds.height * scale)) * 0.5) -
        (sourceBounds.top * scale);

    return Offset((point.dx * scale) + dx, (point.dy * scale) + dy);
  }

  Path _extractPathByProgress(Path path, double progress) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress <= 0.0) return Path();
    if (clampedProgress >= 1.0) return path;

    final result = Path();
    final metrics = path.computeMetrics().toList();
    final totalLength = metrics.fold<double>(
      0.0,
      (length, metric) => length + metric.length,
    );
    var targetLength = totalLength * clampedProgress;

    for (final metric in metrics) {
      if (targetLength <= 0) break;
      final current = targetLength.clamp(0.0, metric.length);
      if (current > 0) {
        result.addPath(metric.extractPath(0, current), Offset.zero);
      }
      targetLength -= metric.length;
    }
    return result;
  }

  void _drawPen(Canvas canvas, Offset tip, double angle, double baseSize) {
    final penScale = baseSize * 0.0035; // Adjusted scale for better proportion

    canvas.save();
    canvas.translate(tip.dx, tip.dy);
    // Offset angle to hold pen naturally
    canvas.rotate(angle - 0.5);

    // Shadow cast by pen on paper
    canvas.drawCircle(
      const Offset(2, 6),
      8 * penScale * 10,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Pen Body Construction
    final paintBody =
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF202020), Color(0xFF000000), Color(0xFF303030)],
          ).createShader(Rect.fromLTWH(-10, -100, 20, 200));

    final paintGold =
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFC6A665), Color(0xFFF8E6B6), Color(0xFF9E7E40)],
          ).createShader(Rect.fromLTWH(-10, -50, 20, 100));

    // 1. Nib
    final nibPath =
        Path()
          ..moveTo(0, 0)
          ..lineTo(-3 * 10 * penScale, -12 * 10 * penScale)
          ..lineTo(3 * 10 * penScale, -12 * 10 * penScale)
          ..close();
    canvas.drawPath(nibPath, paintGold);

    // Nib slit
    canvas.drawLine(
      Offset.zero,
      Offset(0, -10 * 10 * penScale),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.8)
        ..strokeWidth = 1,
    );

    // 2. Grip Section
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(0, -22 * 10 * penScale),
          width: 14 * 10 * penScale,
          height: 20 * 10 * penScale,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFF101010),
    );

    // 3. Gold Ring
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(0, -33 * 10 * penScale),
        width: 16 * 10 * penScale,
        height: 3 * 10 * penScale,
      ),
      paintGold,
    );

    // 4. Main Barrel (Extends upwards)
    final barrelPath =
        Path()
          ..moveTo(-8 * 10 * penScale, -35 * 10 * penScale)
          ..lineTo(8 * 10 * penScale, -35 * 10 * penScale)
          ..lineTo(9 * 10 * penScale, -200 * 10 * penScale) // Taper slightly
          ..lineTo(-9 * 10 * penScale, -200 * 10 * penScale)
          ..close();
    canvas.drawPath(barrelPath, paintBody);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _WritingPainter oldDelegate) {
    return oldDelegate.writingProgress != writingProgress ||
        oldDelegate.penPosition != penPosition ||
        oldDelegate.penAngle != penAngle ||
        oldDelegate.showPen != showPen;
  }
}

class _SignatureSample {
  const _SignatureSample({required this.position, required this.tangent});
  final Offset position;
  final Offset tangent;
}

// Improved Path: Smoother connections, less jittery, standard cursive flow.
Path _buildRojnivisPath() {
  final path = Path();
  // Starting position (R)
  path.moveTo(0.1, 0.7);

  // R (Capital)
  path.lineTo(0.1, 0.3); // Up stroke
  path.cubicTo(0.1, 0.3, 0.25, 0.25, 0.25, 0.4); // Top loop
  path.cubicTo(0.25, 0.5, 0.1, 0.5, 0.1, 0.5); // Middle connection
  path.quadraticBezierTo(0.15, 0.6, 0.2, 0.7); // Leg down

  // connector to o
  path.quadraticBezierTo(0.22, 0.65, 0.25, 0.6);

  // o
  path.cubicTo(0.22, 0.6, 0.22, 0.75, 0.28, 0.75); // bottom curve
  path.cubicTo(0.33, 0.75, 0.33, 0.6, 0.28, 0.6); // top curve
  path.quadraticBezierTo(0.32, 0.6, 0.35, 0.6); // flick out

  // j
  path.quadraticBezierTo(0.38, 0.6, 0.4, 0.6);
  path.lineTo(0.4, 0.9); // descender
  path.cubicTo(0.4, 1.0, 0.3, 1.0, 0.3, 0.9); // loop bottom
  path.quadraticBezierTo(0.35, 0.8, 0.45, 0.7); // cross back up

  // n
  path.lineTo(0.45, 0.6);
  path.quadraticBezierTo(0.5, 0.58, 0.5, 0.7); // hump 1
  path.quadraticBezierTo(0.5, 0.6, 0.55, 0.6); // up again
  path.quadraticBezierTo(0.6, 0.58, 0.6, 0.7); // hump 2
  path.quadraticBezierTo(0.6, 0.75, 0.65, 0.7); // exit

  // i
  path.lineTo(0.65, 0.6);
  path.lineTo(0.65, 0.7);
  path.quadraticBezierTo(0.65, 0.75, 0.7, 0.7);

  // v
  path.quadraticBezierTo(0.72, 0.6, 0.75, 0.6);
  path.lineTo(0.78, 0.7); // down
  path.lineTo(0.82, 0.6); // up

  // i
  path.lineTo(0.82, 0.7);
  path.quadraticBezierTo(0.82, 0.75, 0.87, 0.7);

  // s
  path.quadraticBezierTo(0.9, 0.6, 0.92, 0.6);
  path.quadraticBezierTo(0.88, 0.65, 0.92, 0.7); // s curve
  path.quadraticBezierTo(0.95, 0.75, 0.85, 0.75); // bottom s

  // Dots
  path.addOval(Rect.fromCircle(center: const Offset(0.65, 0.55), radius: 0.01));
  path.addOval(Rect.fromCircle(center: const Offset(0.82, 0.55), radius: 0.01));

  // Note: This is an abstract normalized path (0.0 -> 1.0).
  // The visualizer scales it to the book page.
  return path;
}
