import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:sliver_tools/sliver_tools.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';
import '../../data/models/journal_entry_model.dart';
import '../bloc/journal_bloc.dart';
import '../../../../core/services/sound_service.dart';
import '../../../../di/injection.dart';

enum ViewMode { list, grid, calendar }

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  ViewMode _viewMode = ViewMode.list;

  // Calendar specific state
  late DateTime _selectedDay;
  final ScrollController _calendarScrollController = ScrollController();
  final List<DateTime> _days = [];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = DateTime(today.year, today.month, today.day);

    // Generate 30 days back and 30 days forward
    for (int i = -30; i <= 30; i++) {
      _days.add(_selectedDay.add(Duration(days: i)));
    }
  }

  @override
  void dispose() {
    _calendarScrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    final index = _days.indexWhere((day) => _isSameDay(day, _selectedDay));
    if (index != -1 && _calendarScrollController.hasClients) {
      final offset =
          (index * 68.0) - (MediaQuery.of(context).size.width / 2) + 34.0;
      _calendarScrollController.animateTo(
        offset.clamp(0.0, _calendarScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<JournalEntryModel> _getEventsForDay(
    DateTime day,
    List<JournalEntryModel> allEntries,
  ) {
    return allEntries.where((entry) => _isSameDay(entry.date, day)).toList();
  }

  String _getMoodEmoji(int moodIndex) {
    switch (moodIndex) {
      case 0:
        return '😊';
      case 1:
        return '😔';
      case 2:
        return '😐';
      case 3:
        return '🤩';
      case 4:
        return '😠';
      default:
        return '😐';
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
                  onPressed: () => context.push('/home/mindmap'),
                  icon: const Icon(Icons.account_tree_outlined),
                  tooltip: 'mind_maps'.tr(),
                ),
                const SizedBox(width: 4),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 16.0,
                ),
                child: Center(
                  child: SegmentedButton<ViewMode>(
                    showSelectedIcon: false,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.2);
                        }
                        return Colors.transparent;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((
                        states,
                      ) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.primary;
                        }
                        return Theme.of(context).colorScheme.onSurface;
                      }),
                      side: WidgetStateProperty.all(
                        BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant,
                        ),
                      ),
                    ),
                    segments: const [
                      ButtonSegment(
                        value: ViewMode.list,
                        icon: Icon(Icons.view_list_outlined),
                      ),
                      ButtonSegment(
                        value: ViewMode.grid,
                        icon: Icon(Icons.grid_view_outlined),
                      ),
                      ButtonSegment(
                        value: ViewMode.calendar,
                        icon: Icon(Icons.calendar_month_outlined),
                      ),
                    ],
                    selected: {_viewMode},
                    onSelectionChanged: (selection) {
                      setState(() {
                        _viewMode = selection.first;
                        if (_viewMode == ViewMode.calendar) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _scrollToSelectedDay();
                          });
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: QuickQuestionCard(
                onUseQuestion: (question) {
                  context.push(
                    '/home/add-entry?initialContent=${Uri.encodeComponent(question)}\n\n',
                  );
                },
              ),
            ),
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
                if (entries.isEmpty && !state.filter.hasActiveFilters) {
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

                Widget viewChild;
                if (_viewMode == ViewMode.list) {
                  viewChild = _buildListView(context, state.entries);
                } else if (_viewMode == ViewMode.grid) {
                  viewChild = _buildGridView(context, state.entries);
                } else {
                  viewChild = _buildCalendarView(context, state.entries);
                }

                return SliverAnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: viewChild,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListView(BuildContext context, List<JournalEntryModel> entries) {
    return SliverPadding(
      key: const ValueKey('list_view'),
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
                          content: Text('delete_entry_confirm'.tr()),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: Text('cancel'.tr()),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.of(context).pop(true),
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('deleted'.tr())));
            },
            child: _EntryCard(
              title: entry.title,
              subtitle: entry.content,
              date: entry.date,
              onTap: () {
                getIt<SoundService>().playPageFlip();
                context.push('/home/entry/${entry.id}');
              },
              onEdit: () => context.push('/home/add-entry?entryId=${entry.id}'),
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
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text(cancelText),
                          ),
                          FilledButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text(deleteText),
                          ),
                        ],
                      ),
                ).then((shouldDelete) {
                  if (shouldDelete != true) return;
                  journalBloc.add(DeleteEntryRequested(entryId: entry.id));
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
  }

  Widget _buildGridView(BuildContext context, List<JournalEntryModel> entries) {
    return SliverPadding(
      key: const ValueKey('grid_view'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      sliver: SliverGrid(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        delegate: SliverChildBuilderDelegate((context, index) {
          final entry = entries[index];
          return AppCard(
            onTap: () {
              getIt<SoundService>().playPageFlip();
              context.push('/home/entry/${entry.id}');
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getMoodEmoji(entry.moodIndex),
                        style: const TextStyle(fontSize: 24),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Expanded(
                    child: Text(
                      entry.content,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat.MMMd(
                      context.locale.toString(),
                    ).format(entry.date),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: entries.length),
      ),
    );
  }

  Widget _buildCalendarView(
    BuildContext context,
    List<JournalEntryModel> entries,
  ) {
    final selectedEntries = _getEventsForDay(_selectedDay, entries);

    return SliverToBoxAdapter(
      key: const ValueKey('calendar_view'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Horizontal Day Selector
          SizedBox(
            height: 90,
            child: ListView.builder(
              controller: _calendarScrollController,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _days.length,
              itemBuilder: (context, index) {
                final day = _days[index];
                final isSelected = _isSameDay(day, _selectedDay);
                final isToday = _isSameDay(day, DateTime.now());
                final dayEntries = _getEventsForDay(day, entries);

                // If it's not selected, not today, and has NO entries, we hide the card entirely
                // This makes it a data-only calendar.
                if (!isSelected && !isToday && dayEntries.isEmpty) {
                  return const SizedBox.shrink();
                }

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDay = day;
                      _scrollToSelectedDay();
                    });
                  },
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.2)
                              : Theme.of(
                                context,
                              ).colorScheme.surface.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : (isToday
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.primary.withValues(alpha: 0.5)
                                    : Colors.transparent),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat.E(
                            context.locale.toString(),
                          ).format(day).toUpperCase(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          day.day.toString(),
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Tiny indicators for entries
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children:
                              dayEntries.take(3).map((e) {
                                return Container(
                                  width: 4,
                                  height: 4,
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected
                                            ? Theme.of(
                                              context,
                                            ).colorScheme.primary
                                            : Theme.of(
                                              context,
                                            ).colorScheme.onSurface,
                                    shape: BoxShape.circle,
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.yMMMMd(
                    context.locale.toString(),
                  ).format(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDay,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _selectedDay = picked;
                        if (!_days.any((d) => _isSameDay(d, picked))) {
                          // Expand days list if outside range
                          _days.clear();
                          for (int i = -30; i <= 30; i++) {
                            _days.add(_selectedDay.add(Duration(days: i)));
                          }
                        }
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToSelectedDay();
                        });
                      });
                    }
                  },
                  icon: const Icon(Icons.date_range, size: 18),
                  label: Text('select_date'.tr()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          selectedEntries.isEmpty
              ? Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history_edu,
                      size: 48,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'no_entries'.tr(),
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                itemCount: selectedEntries.length,
                itemBuilder: (context, index) {
                  final entry = selectedEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
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
                        showDialog<bool>(
                          context: context,
                          builder:
                              (context) => AlertDialog(
                                title: Text('delete_entry'.tr()),
                                content: Text('delete_entry_confirm'.tr()),
                                actions: [
                                  TextButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(false),
                                    child: Text('cancel'.tr()),
                                  ),
                                  FilledButton(
                                    onPressed:
                                        () => Navigator.of(context).pop(true),
                                    child: Text('delete'.tr()),
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
        ],
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
