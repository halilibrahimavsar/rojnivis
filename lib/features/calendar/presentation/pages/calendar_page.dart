import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../journal/data/models/journal_entry_model.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';
import '../../../../core/widgets/app_card.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late DateTime _selectedDay;
  final ScrollController _scrollController = ScrollController();
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDay();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToSelectedDay() {
    final index = _days.indexWhere((day) => _isSameDay(day, _selectedDay));
    if (index != -1 && _scrollController.hasClients) {
      // Approximate width of each day item + padding
      final offset =
          (index * 68.0) - (MediaQuery.of(context).size.width / 2) + 34.0;
      _scrollController.animateTo(
        offset.clamp(0.0, _scrollController.position.maxScrollExtent),
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
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: Text('calendar'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.today),
            onPressed: () {
              final today = DateTime.now();
              setState(() {
                _selectedDay = DateTime(today.year, today.month, today.day);
                _scrollToSelectedDay();
              });
            },
          ),
        ],
      ),
      body: BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) {
          List<JournalEntryModel> entries = [];
          if (state is JournalLoaded) {
            entries = state.entries;
          }

          final selectedEntries = _getEventsForDay(_selectedDay, entries);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Horizontal Day Selector
              SizedBox(
                height: 90,
                child: ListView.builder(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _days.length,
                  itemBuilder: (context, index) {
                    final day = _days[index];
                    final isSelected = _isSameDay(day, _selectedDay);
                    final isToday = _isSameDay(day, DateTime.now());
                    final dayEntries = _getEventsForDay(day, entries);

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
                                        ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.5)
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
                child: Text(
                  DateFormat.yMMMMd(
                    context.locale.toString(),
                  ).format(_selectedDay),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Expanded(
                child:
                    selectedEntries.isEmpty
                        ? Center(
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
                                style: Theme.of(
                                  context,
                                ).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        )
                        : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: selectedEntries.length,
                          itemBuilder: (context, index) {
                            final entry = selectedEntries[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: AppCard(
                                onTap:
                                    () =>
                                        context.push('/home/entry/${entry.id}'),
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Text(
                                      _getMoodEmoji(entry.moodIndex),
                                      style: const TextStyle(fontSize: 32),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            entry.title.trim().isEmpty
                                                ? 'untitled'.tr()
                                                : entry.title,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            entry.content,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style:
                                                Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
              ),
            ],
          );
        },
      ),
    );
  }
}
