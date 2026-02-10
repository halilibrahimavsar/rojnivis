import 'package:flutter/material.dart';

/// A staggered fade-and-slide animation for list items.
///
/// Wraps individual items in a list to create a fluid cascading effect
/// as content loads. Items slide up from below while fading in, with
/// each item slightly delayed to create a waterfall effect.
///
/// Example:
/// ```dart
/// ListView.builder(
///   itemCount: items.length,
///   itemBuilder: (context, index) => FadeSlideTransition(
///     index: index,
///     child: MyListTile(item: items[index]),
///   ),
/// )
/// ```
class FadeSlideTransition extends StatefulWidget {
  /// The child widget to animate.
  final Widget child;

  /// Index of this item in the list (used for stagger delay).
  final int index;

  /// Duration of each item's animation.
  final Duration duration;

  /// Delay between successive items.
  final Duration staggerDelay;

  /// Vertical offset to slide from.
  final double slideOffset;

  /// The curve for the animation.
  final Curve curve;

  const FadeSlideTransition({
    super.key,
    required this.child,
    required this.index,
    this.duration = const Duration(milliseconds: 400),
    this.staggerDelay = const Duration(milliseconds: 60),
    this.slideOffset = 30.0,
    this.curve = Curves.easeOutCubic,
  });

  @override
  State<FadeSlideTransition> createState() => _FadeSlideTransitionState();
}

class _FadeSlideTransitionState extends State<FadeSlideTransition>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    ));

    // Stagger the animation start based on index
    final delay = widget.staggerDelay * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
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
        return Transform.translate(
          offset: _slideAnimation.value,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Wraps a [ScrollController] based list with auto-animated children.
///
/// Use this to apply fade-slide animations to an entire scrollable list
/// automatically without manually wrapping each item.
class AnimatedListBuilder extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;
  final EdgeInsets? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AnimatedListBuilder({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding,
      physics: physics,
      shrinkWrap: shrinkWrap,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return FadeSlideTransition(
          index: index,
          child: itemBuilder(context, index),
        );
      },
    );
  }
}
