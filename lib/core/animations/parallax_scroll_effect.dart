import 'package:flutter/material.dart';

/// A depth-based parallax scrolling widget for note lists.
///
/// Creates visual depth by making background elements move at a different
/// speed than foreground elements as the user scrolls. This creates a
/// premium, immersive feel reminiscent of luxury physical notebooks.
///
/// Example:
/// ```dart
/// ParallaxScrollEffect(
///   backgroundWidget: NotebookTexture(),
///   child: ListView(...),
/// )
/// ```
class ParallaxScrollEffect extends StatefulWidget {
  /// The main scrollable content.
  final Widget child;

  /// Background widget that moves at a slower speed.
  final Widget? backgroundWidget;

  /// Parallax factor: 0.0 = no movement, 1.0 = same speed as scroll.
  /// Values between 0.3-0.5 feel natural.
  final double parallaxFactor;

  /// The axis of the parallax effect.
  final Axis axis;

  const ParallaxScrollEffect({
    super.key,
    required this.child,
    this.backgroundWidget,
    this.parallaxFactor = 0.35,
    this.axis = Axis.vertical,
  });

  @override
  State<ParallaxScrollEffect> createState() => _ParallaxScrollEffectState();
}

class _ParallaxScrollEffectState extends State<ParallaxScrollEffect> {
  double _scrollOffset = 0;

  bool _onScrollNotification(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification) {
      setState(() {
        _scrollOffset = notification.metrics.pixels;
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: Stack(
        children: [
          // Parallax background layer
          if (widget.backgroundWidget != null)
            Transform.translate(
              offset: widget.axis == Axis.vertical
                  ? Offset(0, -_scrollOffset * widget.parallaxFactor)
                  : Offset(-_scrollOffset * widget.parallaxFactor, 0),
              child: widget.backgroundWidget,
            ),
          // Foreground content
          widget.child,
        ],
      ),
    );
  }
}

/// A single parallax list item that moves at a depth-dependent speed.
///
/// Use within a ScrollView to create items that have individual depth.
/// Deeper items (lower depth values) move slower, creating a layered effect.
class ParallaxListItem extends StatelessWidget {
  /// The child widget.
  final Widget child;

  /// Depth of this item (0.0 = background, 1.0 = foreground).
  final double depth;

  /// The global key used to calculate position.
  final GlobalKey _itemKey = GlobalKey();

  ParallaxListItem({
    super.key,
    required this.child,
    this.depth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Flow(
      delegate: _ParallaxFlowDelegate(
        scrollable: Scrollable.of(context),
        itemContext: context,
        itemKey: _itemKey,
        depth: depth,
      ),
      children: [
        SizedBox(key: _itemKey, child: child),
      ],
    );
  }
}

class _ParallaxFlowDelegate extends FlowDelegate {
  final ScrollableState scrollable;
  final BuildContext itemContext;
  final GlobalKey itemKey;
  final double depth;

  _ParallaxFlowDelegate({
    required this.scrollable,
    required this.itemContext,
    required this.itemKey,
    required this.depth,
  }) : super(repaint: scrollable.position);

  @override
  BoxConstraints getConstraintsForChild(int i, BoxConstraints constraints) {
    return BoxConstraints.tightFor(width: constraints.maxWidth);
  }

  @override
  void paintChildren(FlowPaintingContext context) {
    // Calculate the position of this item within the viewport
    final scrollableBox =
        scrollable.context.findRenderObject() as RenderBox;
    final itemBox = itemKey.currentContext?.findRenderObject() as RenderBox?;
    if (itemBox == null) {
      context.paintChild(0);
      return;
    }

    final itemOffset = itemBox.localToGlobal(
      Offset.zero,
      ancestor: scrollableBox,
    );

    // Calculate parallax offset based on position in viewport
    final viewportDimension = scrollable.position.viewportDimension;
    final scrollFraction = (itemOffset.dy / viewportDimension).clamp(-1.0, 2.0);
    final parallaxOffset = scrollFraction * 20 * (1 - depth);

    context.paintChild(
      0,
      transform: Matrix4.translationValues(0, parallaxOffset, 0),
    );
  }

  @override
  bool shouldRepaint(_ParallaxFlowDelegate oldDelegate) {
    return scrollable != oldDelegate.scrollable ||
        itemContext != oldDelegate.itemContext ||
        depth != oldDelegate.depth;
  }
}

/// Animated notebook paper texture that subtly responds to scroll position.
///
/// Creates faint ruled lines and a paper grain effect that shifts with
/// the parallax, enhancing the luxury notebook feel.
class NotebookPaperBackground extends StatelessWidget {
  /// Color of the ruled lines.
  final Color lineColor;

  /// Spacing between lines in logical pixels.
  final double lineSpacing;

  /// Paper background color hint.
  final Color paperColor;

  const NotebookPaperBackground({
    super.key,
    this.lineColor = const Color(0x0E8B9FC5),
    this.lineSpacing = 28.0,
    this.paperColor = const Color(0xFFFFFEF7),
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        painter: _NotebookPaperPainter(
          lineColor: lineColor,
          lineSpacing: lineSpacing,
          paperColor: paperColor,
        ),
      ),
    );
  }
}

class _NotebookPaperPainter extends CustomPainter {
  final Color lineColor;
  final double lineSpacing;
  final Color paperColor;

  _NotebookPaperPainter({
    required this.lineColor,
    required this.lineSpacing,
    required this.paperColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw paper background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = paperColor,
    );

    // Draw horizontal ruled lines
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    double y = lineSpacing;
    while (y < size.height) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        linePaint,
      );
      y += lineSpacing;
    }

    // Draw left margin line
    final marginPaint = Paint()
      ..color = lineColor.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      const Offset(40, 0),
      Offset(40, size.height),
      marginPaint,
    );
  }

  @override
  bool shouldRepaint(_NotebookPaperPainter oldDelegate) =>
      lineColor != oldDelegate.lineColor ||
      lineSpacing != oldDelegate.lineSpacing;
}
