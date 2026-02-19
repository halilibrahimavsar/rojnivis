import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/themed_paper.dart';

/// A card that displays an AI-generated summary with a fade-in animation.
class AiSummaryCard extends StatelessWidget {
  final String summary;
  final VoidCallback onRefresh;
  final bool isLoading;

  const AiSummaryCard({
    super.key,
    required this.summary,
    required this.onRefresh,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedPaper(
      padding: const EdgeInsets.all(16),
      applyPageStudio: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'summary'.tr(),
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isLoading)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                IconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  onPressed: onRefresh,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary.isEmpty ? 'generating_summary'.tr() : summary,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
