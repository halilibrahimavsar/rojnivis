import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A collection of premium micro-interaction helpers for Rojnivis.
///
/// This library provides reusable animation widgets that create a
/// polished, luxury feel throughout the application.

// ─────────────────────────────────────────────────────────────────
// 1. Scale Bounce Feedback
// ─────────────────────────────────────────────────────────────────

/// A widget that provides a satisfying scale-bounce effect on tap.
///
/// Wraps any tappable widget with a spring-like scale animation that
/// provides premium tactile feedback.
class ScaleBounceTap extends StatefulWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Called when the widget is tapped.
  final VoidCallback? onTap;

  /// How much to scale down on press (0.0 - 1.0).
  final double scaleDown;

  /// Duration of the bounce animation.
  final Duration duration;

  const ScaleBounceTap({
    super.key,
    required this.child,
    this.onTap,
    this.scaleDown = 0.95,
    this.duration = const Duration(milliseconds: 120),
  });

  @override
  State<ScaleBounceTap> createState() => _ScaleBounceTapState();
}

class _ScaleBounceTapState extends State<ScaleBounceTap>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: widget.scaleDown,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 2. Shimmer Loading Effect
// ─────────────────────────────────────────────────────────────────

/// A premium shimmer loading effect for skeleton screens.
///
/// Displays a sweeping highlight animation across a placeholder,
/// creating a polished indication that content is loading.
class ShimmerEffect extends StatefulWidget {
  /// The child widget to apply shimmer to (usually a Container).
  final Widget child;

  /// Base color of the shimmer.
  final Color baseColor;

  /// Highlight color of the shimmer sweep.
  final Color highlightColor;

  /// Duration of one shimmer sweep.
  final Duration duration;

  /// Whether the effect is enabled.
  final bool enabled;

  const ShimmerEffect({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFFE0E0E0),
    this.highlightColor = const Color(0xFFF5F5F5),
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  @override
  State<ShimmerEffect> createState() => _ShimmerEffectState();
}

class _ShimmerEffectState extends State<ShimmerEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    if (widget.enabled) _controller.repeat();
  }

  @override
  void didUpdateWidget(ShimmerEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: const Alignment(-1.5, -0.3),
              end: const Alignment(1.5, 0.3),
              transform:
                  _SlidingGradientTransform(percent: _controller.value),
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;

  const _SlidingGradientTransform({required this.percent});

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (percent * 2 - 1), 0, 0);
  }
}

// ─────────────────────────────────────────────────────────────────
// 3. Morphing Card Transition
// ─────────────────────────────────────────────────────────────────

/// A card widget that morphs between collapsed and expanded states.
///
/// Use for journal entry cards that expand to show full content,
/// creating smooth shape and size transitions.
class MorphingCard extends StatelessWidget {
  /// Whether the card is in its expanded state.
  final bool isExpanded;

  /// The collapsed card content.
  final Widget collapsedChild;

  /// The expanded card content.
  final Widget expandedChild;

  /// Border radius when collapsed.
  final double collapsedRadius;

  /// Border radius when expanded.
  final double expandedRadius;

  /// Background color of the card.
  final Color? backgroundColor;

  /// Called when the card is tapped.
  final VoidCallback? onTap;

  /// Animation duration.
  final Duration duration;

  const MorphingCard({
    super.key,
    required this.isExpanded,
    required this.collapsedChild,
    required this.expandedChild,
    this.collapsedRadius = 20.0,
    this.expandedRadius = 12.0,
    this.backgroundColor,
    this.onTap,
    this.duration = const Duration(milliseconds: 350),
  });

  @override
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? Theme.of(context).cardColor;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: duration,
        curve: Curves.easeInOutCubic,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(
            isExpanded ? expandedRadius : collapsedRadius,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isExpanded ? 0.12 : 0.06,
              ),
              blurRadius: isExpanded ? 24 : 8,
              offset: Offset(0, isExpanded ? 8 : 2),
            ),
          ],
        ),
        child: AnimatedCrossFade(
          duration: duration,
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: collapsedChild,
          secondChild: expandedChild,
          firstCurve: Curves.easeInOutCubic,
          secondCurve: Curves.easeInOutCubic,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 4. Pulse Effect
// ─────────────────────────────────────────────────────────────────

/// A gentle pulsing glow effect, ideal for highlighting AI-generated
/// insights, active elements, or important notifications.
class PulseEffect extends StatefulWidget {
  /// The child widget to pulse.
  final Widget child;

  /// Color of the pulse glow.
  final Color glowColor;

  /// Maximum spread of the glow.
  final double maxGlowRadius;

  /// Duration of one pulse cycle.
  final Duration pulseDuration;

  /// Whether the pulse is active.
  final bool active;

  const PulseEffect({
    super.key,
    required this.child,
    this.glowColor = const Color(0xFF6C5CE7),
    this.maxGlowRadius = 12.0,
    this.pulseDuration = const Duration(milliseconds: 1600),
    this.active = true,
  });

  @override
  State<PulseEffect> createState() => _PulseEffectState();
}

class _PulseEffectState extends State<PulseEffect>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pulseDuration,
      vsync: this,
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(PulseEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final glowValue =
            math.sin(_controller.value * math.pi) * widget.maxGlowRadius;
        return Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(
                  alpha: 0.3 * (1 - _controller.value * 0.5),
                ),
                blurRadius: glowValue,
                spreadRadius: glowValue * 0.3,
              ),
            ],
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// 5. Smooth Page Indicator
// ─────────────────────────────────────────────────────────────────

/// A smooth, animated page indicator with premium dot transitions.
class SmoothPageIndicator extends StatelessWidget {
  /// Total number of pages.
  final int count;

  /// Current page index (can be fractional for smooth animation).
  final double currentPage;

  /// Active dot color.
  final Color activeColor;

  /// Inactive dot color.
  final Color inactiveColor;

  /// Dot size.
  final double dotSize;

  /// Spacing between dots.
  final double spacing;

  const SmoothPageIndicator({
    super.key,
    required this.count,
    required this.currentPage,
    this.activeColor = const Color(0xFF6C5CE7),
    this.inactiveColor = const Color(0xFFE0E0E0),
    this.dotSize = 8.0,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(count, (index) {
        final distance = (currentPage - index).abs();
        final scale = (1 - distance.clamp(0.0, 1.0)) * 0.5 + 0.5;
        final color = Color.lerp(
              inactiveColor,
              activeColor,
              (1 - distance.clamp(0.0, 1.0)),
            ) ??
            inactiveColor;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: spacing / 2),
          width: dotSize * (1 + (1 - distance.clamp(0.0, 1.0)) * 0.8),
          height: dotSize * scale,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(dotSize),
          ),
        );
      }),
    );
  }
}
