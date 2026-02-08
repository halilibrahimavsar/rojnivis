import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.backgroundColor,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadiusGeometry borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).extension<AppThemeStyle>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardColor = backgroundColor ?? Theme.of(context).cardColor;
    final borderRadiusResolved =
        borderRadius is BorderRadius
            ? borderRadius as BorderRadius
            : BorderRadius.circular(20);

    final content = Padding(padding: padding, child: child);

    final tappable =
        onTap == null
            ? content
            : InkWell(
              onTap: onTap,
              borderRadius: borderRadiusResolved,
              child: content,
            );

    Widget built;
    if (style?.isGlass == true) {
      built = ClipRRect(
        borderRadius: borderRadiusResolved,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: cardColor.withValues(alpha: isDark ? 0.40 : 0.60),
              borderRadius: borderRadiusResolved,
              border: Border.all(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.08,
                ),
              ),
            ),
            child: Material(type: MaterialType.transparency, child: tappable),
          ),
        ),
      );
    } else if (style?.isNeomorphic == true) {
      final base = Theme.of(context).scaffoldBackgroundColor;
      built = DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: borderRadiusResolved,
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.white : Colors.white).withValues(
                alpha: isDark ? 0.04 : 0.75,
              ),
              offset: const Offset(-8, -8),
              blurRadius: 18,
            ),
            BoxShadow(
              color: (isDark ? Colors.black : Colors.black).withValues(
                alpha: isDark ? 0.55 : 0.14,
              ),
              offset: const Offset(8, 8),
              blurRadius: 18,
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
      built = Card(margin: EdgeInsets.zero, child: tappable);
    }

    if (margin == null) return built;
    return Padding(padding: margin!, child: built);
  }
}
