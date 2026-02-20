import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';
import '../../domain/models/filter_model.dart';
import '../bloc/journal_bloc.dart';
import '../widgets/filter_dialog.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../di/injection.dart';

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  Future<void> _showFilterDialog() async {
    final state = context.read<JournalBloc>().state;
    JournalFilter currentFilter = const JournalFilter();
    if (state is JournalLoaded) {
      currentFilter = state.filter;
    }

    final result = await showDialog<JournalFilter>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: currentFilter),
    );

    if (result != null) {
      if (!mounted) return;
      context.read<JournalBloc>().add(SearchRequested(filter: result));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is UnauthenticatedState) {
          context.go('/public');
        }
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Colors.transparent,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              title: Text('app_title'.tr()),
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  onPressed: _showFilterDialog,
                  icon: const Icon(Icons.filter_list_outlined),
                  tooltip: 'filter'.tr(),
                ),
                IconButton(
                  onPressed: () => context.push('/home/mindmap'),
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: 'mind_maps'.tr(),
                ),
                const SizedBox(width: 4),
              ],
            ),
            const SliverToBoxAdapter(child: QuickQuestionCard()),
            BlocBuilder<JournalBloc, JournalState>(
              builder: (context, state) {
                if (state is JournalLoading ||
                    state is JournalInitial ||
                    state is JournalActionInProgress) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is JournalError || state is JournalActionError) {
                  final message =
                      state is JournalError
                          ? state.message
                          : (state as JournalActionError).message;
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(message, textAlign: TextAlign.center),
                      ),
                    ),
                  );
                }

                if (state is! JournalLoaded) {
                  return const SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final entries = state.entries;
                if (entries.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome_outlined,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'empty_journal'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton.icon(
                              onPressed: () => context.push('/home/add-entry'),
                              icon: const Icon(Icons.edit_outlined),
                              label: Text('create_entry'.tr()),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  sliver: SliverList.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return Dismissible(
                        key: ValueKey(entry.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                        confirmDismiss: (_) async {
                          return await showDialog<bool>(
                                context: context,
                                builder:
                                    (context) => AlertDialog(
                                      title: Text('delete_entry'.tr()),
                                      content: Text(
                                        'delete_entry_confirm'.tr(),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(false),
                                          child: Text('cancel'.tr()),
                                        ),
                                        FilledButton(
                                          onPressed:
                                              () => Navigator.of(
                                                context,
                                              ).pop(true),
                                          child: Text('delete'.tr()),
                                        ),
                                      ],
                                    ),
                              ) ??
                              false;
                        },
                        onDismissed: (_) {
                          context.read<JournalBloc>().add(
                            DeleteEntryRequested(entryId: entry.id),
                          );
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('deleted'.tr())),
                          );
                        },
                        child: _EntryCard(
                          title: entry.title,
                          subtitle: entry.content,
                          date: entry.date,
                          onTap: () {
                            getIt<SoundService>().playPageFlip();
                            context.push('/home/entry/${entry.id}');
                          },
                          onEdit:
                              () => context.push(
                                '/home/add-entry?entryId=${entry.id}',
                              ),
                          onDelete: () {
                            final journalBloc = context.read<JournalBloc>();
                            final messenger = ScaffoldMessenger.of(context);
                            final deletedMessage = 'deleted'.tr();
                            final deleteTitle = 'delete_entry'.tr();
                            final deleteContent = 'delete_entry_confirm'.tr();
                            final cancelText = 'cancel'.tr();
                            final deleteText = 'delete'.tr();

                            showDialog<bool>(
                              context: context,
                              builder:
                                  (context) => AlertDialog(
                                    title: Text(deleteTitle),
                                    content: Text(deleteContent),
                                    actions: [
                                      TextButton(
                                        onPressed:
                                            () => Navigator.of(
                                              context,
                                            ).pop(false),
                                        child: Text(cancelText),
                                      ),
                                      FilledButton(
                                        onPressed:
                                            () =>
                                                Navigator.of(context).pop(true),
                                        child: Text(deleteText),
                                      ),
                                    ],
                                  ),
                            ).then((shouldDelete) {
                              if (shouldDelete != true) return;
                              journalBloc.add(
                                DeleteEntryRequested(entryId: entry.id),
                              );
                              messenger.showSnackBar(
                                SnackBar(content: Text(deletedMessage)),
                              );
                            });
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  const _EntryCard({
    required this.title,
    required this.subtitle,
    required this.date,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final DateTime date;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final formattedDate = DateFormat.yMMMMd(locale).add_Hm().format(date);

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  title.trim().isEmpty ? 'untitled'.tr() : title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder:
                    (context) => [
                      PopupMenuItem(value: 'edit', child: Text('edit'.tr())),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('delete'.tr()),
                      ),
                    ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
