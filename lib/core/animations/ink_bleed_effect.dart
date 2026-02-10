import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A custom-painted ink bleed effect that simulates ink spreading on paper.
///
/// This widget creates a luxury notebook feel by rendering subtle ink-bleed
/// halos around text as it's typed. The effect gently pulses and spreads
/// outward, mimicking the way fountain pen ink bleeds on premium paper.
///
/// Example:
/// ```dart
/// InkBleedEffect(
///   isActive: _isTyping,
///   color: Theme.of(context).primaryColor,
///   child: TextField(...),
/// )
/// ```
class InkBleedEffect extends StatefulWidget {
  /// The child widget (typically a text input).
  final Widget child;

  /// Whether the bleed effect is currently active (e.g., while typing).
  final bool isActive;

  /// Base color of the ink bleed.
  final Color color;

  /// Maximum radius of the bleed spread.
  final double maxRadius;

  /// Duration of one bleed pulse cycle.
  final Duration pulseDuration;

  const InkBleedEffect({
    super.key,
    required this.child,
    this.isActive = false,
    this.color = const Color(0xFF1A1A2E),
    this.maxRadius = 24.0,
    this.pulseDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<InkBleedEffect> createState() => _InkBleedEffectState();
}

class _InkBleedEffectState extends State<InkBleedEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnimation;
  late final Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );

    _radiusAnimation = Tween<double>(
      begin: 0.0,
      end: widget.maxRadius,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _opacityAnimation = Tween<double>(
      begin: 0.15,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    if (widget.isActive) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(InkBleedEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive && !oldWidget.isActive) {
      _controller.repeat();
    } else if (!widget.isActive && oldWidget.isActive) {
      _controller.forward().then((_) {
        if (mounted) _controller.reset();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          foregroundPainter: widget.isActive || _controller.isAnimating
              ? _InkBleedPainter(
                  radius: _radiusAnimation.value,
                  opacity: _opacityAnimation.value,
                  color: widget.color,
                )
              : null,
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _InkBleedPainter extends CustomPainter {
  final double radius;
  final double opacity;
  final Color color;

  _InkBleedPainter({
    required this.radius,
    required this.opacity,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0 || radius <= 0) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.6);

    // Draw multiple overlapping circles for organic ink bleed look
    final random = math.Random(42); // Fixed seed for consistency
    final center = Offset(size.width * 0.5, size.height * 0.5);

    for (var i = 0; i < 5; i++) {
      final offsetX = (random.nextDouble() - 0.5) * radius * 0.4;
      final offsetY = (random.nextDouble() - 0.5) * radius * 0.3;
      final spotRadius = radius * (0.5 + random.nextDouble() * 0.5);

      canvas.drawCircle(
        center + Offset(offsetX, offsetY),
        spotRadius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_InkBleedPainter oldDelegate) =>
      radius != oldDelegate.radius || opacity != oldDelegate.opacity;
}

/// A text cursor that simulates fountain pen ink drip effect.
///
/// Place this adjacent to a text cursor position to create the impression
/// of a premium writing instrument.
class FountainPenCursor extends StatefulWidget {
  /// Current position offset for the cursor.
  final Offset position;

  /// Color of the pen tip.
  final Color color;

  /// Whether the cursor is visible.
  final bool visible;

  const FountainPenCursor({
    super.key,
    required this.position,
    this.color = const Color(0xFF1A1A2E),
    this.visible = true,
  });

  @override
  State<FountainPenCursor> createState() => _FountainPenCursorState();
}

class _FountainPenCursorState extends State<FountainPenCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible) return const SizedBox.shrink();

    return Positioned(
      left: widget.position.dx,
      top: widget.position.dy,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final scale = 1.0 + _pulseController.value * 0.15;
          return Transform.scale(
            scale: scale,
            child: Container(
              width: 3,
              height: 20,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
