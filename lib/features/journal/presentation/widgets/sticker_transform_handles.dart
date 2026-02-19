import 'package:flutter/material.dart';

class StickerTransformHandles extends StatelessWidget {
  const StickerTransformHandles({
    super.key,
    required this.onDelete,
  });

  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: color.withValues(alpha: 0.8), width: 1.4),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            Positioned(
              right: -12,
              top: -12,
              child: GestureDetector(
                onTap: onDelete,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
