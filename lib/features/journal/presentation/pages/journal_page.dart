import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const JournalView();
  }
}

class JournalView extends StatefulWidget {
  const JournalView({super.key});

  @override
  State<JournalView> createState() => _JournalViewState();
}

class _JournalViewState extends State<JournalView> {
  final _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C5CE7), const Color(0xFF00CEC9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('app_title'.tr()),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
          IconButton(
            icon: const Icon(Icons.category),
            onPressed: () => context.push('/categories'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'search_hint'.tr(),
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
              ),
              onChanged: (value) {
                context.read<JournalBloc>().add(SearchJournalEntries(value));
              },
            ),
          ),
        ),
      ),
      body: BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) {
          if (state is JournalLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is JournalLoaded) {
            final entries = state.entries;
            return CustomScrollView(
              slivers: [
                const SliverToBoxAdapter(child: QuickQuestionCard()),
                if (entries.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: Text('No entries yet. Start writing!'),
                    ),
                  )
                else
                  SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final entry = entries[index];
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors:
                                Theme.of(context).brightness == Brightness.light
                                    ? [Colors.white, Colors.grey.shade50]
                                    : [
                                      const Color(0xFF1F293A),
                                      const Color(0xFF2A2F4A),
                                    ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(
                                Theme.of(context).brightness == Brightness.light
                                    ? 0.05
                                    : 0.2,
                              ),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.push('/entry/${entry.id}');
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withOpacity(0.2),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withOpacity(0.2),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        child: Text(
                                          DateFormat.yMMMd().format(entry.date),
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelSmall?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.surface,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                0.1,
                                              ),
                                              blurRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          _getMoodIcon(entry.mood),
                                          size: 20,
                                          color:
                                              Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    entry.title,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    entry.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      height: 1.5,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.color
                                          ?.withOpacity(0.8),
                                    ),
                                  ),
                                  if (entry.tags.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children:
                                          entry.tags
                                              .map(
                                                (tag) => Container(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 12,
                                                        vertical: 6,
                                                      ),
                                                  decoration: BoxDecoration(
                                                    gradient: LinearGradient(
                                                      colors: [
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .primary
                                                            .withOpacity(0.1),
                                                        Theme.of(context)
                                                            .colorScheme
                                                            .secondary
                                                            .withOpacity(0.1),
                                                      ],
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          16,
                                                        ),
                                                    border: Border.all(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary
                                                          .withOpacity(0.3),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Text(
                                                    '#$tag',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .labelSmall
                                                        ?.copyWith(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary,
                                                        ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }, childCount: entries.length),
                  ),
              ],
            );
          } else if (state is JournalError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox.shrink();
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.push('/add-entry');
        },
        label: Text('create_entry'.tr()),
        icon: const Icon(Icons.add),
      ),
    );
  }

  IconData _getMoodIcon(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Icons.sentiment_very_satisfied;
      case Mood.sad:
        return Icons.sentiment_very_dissatisfied;
      case Mood.neutral:
        return Icons.sentiment_neutral;
      case Mood.excited:
        return Icons.sentiment_satisfied_alt;
      case Mood.angry:
        return Icons.mood_bad;
    }
  }
}
