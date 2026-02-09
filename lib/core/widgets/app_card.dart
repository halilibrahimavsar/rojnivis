import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/sound_service.dart';
import '../../di/injection.dart';

class AppCard extends StatefulWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundColor,
    this.showHoverEffect = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;
  final bool showHoverEffect;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<AppThemeStyle>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = widget.backgroundColor ?? Theme.of(context).cardColor;
    final borderRadiusResolved =
        widget.borderRadius is BorderRadius
            ? widget.borderRadius as BorderRadius
            : BorderRadius.circular(20);

    final content = Padding(padding: widget.padding, child: widget.child);

    final tappable =
        widget.onTap == null
            ? content
            : InkWell(
              onTap: () {
                getIt<SoundService>().playPencilTap();
                widget.onTap?.call();
              },
              onHighlightChanged: (pressed) => setState(() => _isPressed = pressed),
              onHover: (hovered) => setState(() => _isHovered = hovered),
              borderRadius: borderRadiusResolved,
              child: content,
            );

    Widget built;
    if (style?.isGlass == true) {
      built = ClipRRect(
        borderRadius: borderRadiusResolved,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              color: cardColor.withValues(
                alpha:
                    _isHovered
                        ? (isDark ? 0.50 : 0.75)
                        : (isDark ? 0.40 : 0.60),
              ),
              borderRadius: borderRadiusResolved,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: _isHovered ? 0.15 : 0.08,
                ),
              ),
              boxShadow:
                  _isHovered
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ]
                      : [],
            ),
            child: Material(type: MaterialType.transparency, child: tappable),
          ),
        ),
      );
    } else if (style?.isNeomorphic == true) {
      final base = Theme.of(context).scaffoldBackgroundColor;
      built = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: borderRadiusResolved,
          boxShadow:
              _isPressed
                  ? [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.white).withValues(
                        alpha: isDark ? 0.02 : 0.4,
                      ),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black).withValues(
                        alpha: isDark ? 0.3 : 0.05,
                      ),
                      offset: const Offset(-2, -2),
                      blurRadius: 4,
                    ),
                  ]
                  : [
                    BoxShadow(
                      color: (isDark ? Colors.white : Colors.white).withValues(
                        alpha: isDark ? (_isHovered ? 0.06 : 0.04) : 0.75,
                      ),
                      offset: Offset(_isHovered ? -10 : -8, _isHovered ? -10 : -8),
                      blurRadius: _isHovered ? 24 : 18,
                    ),
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.black).withValues(
                        alpha: isDark ? 0.55 : 0.14,
                      ),
                      offset: Offset(_isHovered ? 10 : 8, _isHovered ? 10 : 8),
                      blurRadius: _isHovered ? 24 : 18,
                    ),
                  ],
          border: Border.all(
            color: Color.alphaBlend(
              (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
              base,
            ),
          ),
        ),
        child: Material(
          type: MaterialType.transparency,
          shape: RoundedRectangleBorder(borderRadius: borderRadiusResolved),
          child: tappable,
        ),
      );
    } else {
      built = Card(
        margin: EdgeInsets.zero,
        elevation: _isPressed ? 0 : (_isHovered ? 8 : 1),
        child: tappable,
      );
    }

    final animated = AnimatedScale(
      scale: _isPressed ? 0.98 : (_isHovered && widget.showHoverEffect ? 1.02 : 1.0),
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOutBack,
      child: built,
    );

    if (widget.margin == null) return animated;
    return Padding(padding: widget.margin!, child: animated);
  }
}
