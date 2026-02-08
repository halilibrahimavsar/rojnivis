import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../data/questions.dart';

class QuickQuestionCard extends StatefulWidget {
  const QuickQuestionCard({super.key});

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
    return Card(
      margin: const EdgeInsets.all(16.0),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  onPressed: _refreshQuestion,
                  tooltip: 'New Question',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _question,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
