import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';

class AttachmentBackdrop extends StatelessWidget {
  const AttachmentBackdrop({
    super.key,
    required this.path,
    this.opacity = 0.22,
    this.blurSigma = 14,
  });

  final String path;
  final double opacity;
  final double blurSigma;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) return const SizedBox.shrink();
    final file = File(path);
    if (!file.existsSync()) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final overlay = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        colors.surface.withValues(alpha: 0.15),
        colors.surface.withValues(alpha: 0.45),
      ],
    );

    final image = Image.file(file, fit: BoxFit.cover);
    final filtered =
        blurSigma > 0
            ? ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: blurSigma,
                sigmaY: blurSigma,
              ),
              child: image,
            )
            : image;

    return Positioned.fill(
      child: Opacity(
        opacity: opacity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            filtered,
            DecoratedBox(decoration: BoxDecoration(gradient: overlay)),
          ],
        ),
      ),
    );
  }
}
