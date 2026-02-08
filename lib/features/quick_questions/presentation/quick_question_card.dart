import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/widgets/app_card.dart';
import '../data/questions.dart';

class QuickQuestionCard extends StatefulWidget {
  const QuickQuestionCard({super.key, this.onUseQuestion});

  final ValueChanged<String>? onUseQuestion;

  @override
  State<QuickQuestionCard> createState() => _QuickQuestionCardState();
}

class _QuickQuestionCardState extends State<QuickQuestionCard> {
  late String _question;

  @override
  void initState() {
    super.initState();
    _question = QuickQuestionsRepository.getRandomQuestion();
  }

  void _refreshQuestion() {
    setState(() {
      _question = QuickQuestionsRepository.getRandomQuestion();
    });
  }

  @override
  Widget build(BuildContext context) {
    final onPrimaryContainer = Theme.of(context).colorScheme.onPrimaryContainer;

    return AppCard(
      margin: const EdgeInsets.all(16.0),
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'quick_question'.tr(),
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: onPrimaryContainer,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: _refreshQuestion,
                tooltip: 'new_question'.tr(),
                color: onPrimaryContainer,
                visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _question,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              color: onPrimaryContainer,
            ),
          ),
          if (widget.onUseQuestion != null) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => widget.onUseQuestion?.call(_question),
                icon: const Icon(Icons.call_made, size: 18),
                label: Text('use_question'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: onPrimaryContainer,
                  visualDensity:
                      const VisualDensity(horizontal: -2, vertical: -2),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
