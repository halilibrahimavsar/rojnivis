import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';
import 'package:go_router/go_router.dart';

class HorizontalDateCarousel extends StatefulWidget {
  const HorizontalDateCarousel({
    super.key,
    required this.selectedDate,
    required this.monthlyReminders,
    required this.monthlyEntries,
    required this.onDateSelected,
  });

  final DateTime selectedDate;
  final List<Reminder> monthlyReminders;
  final List<JournalEntry> monthlyEntries;
  final ValueChanged<DateTime> onDateSelected;

  @override
  State<HorizontalDateCarousel> createState() => _HorizontalDateCarouselState();
}

class _HorizontalDateCarouselState extends State<HorizontalDateCarousel> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    final itemWidth = 72.0; // 60 width + 12 right margin
    final initialOffset = (widget.selectedDate.day - 1) * itemWidth;
    // Keep it within bounds roughly
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Color _getColorForDate(DateTime date) {
    final remindersForDate = widget.monthlyReminders.where(
      (r) =>
          r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day,
    );

    if (remindersForDate.isEmpty) return Colors.grey.withValues(alpha: 0.2);

    final highestImportance = remindersForDate.fold<ImportanceLevel>(
      ImportanceLevel.low,
      (max, reminder) =>
          reminder.importanceLevel.index > max.index
              ? reminder.importanceLevel
              : max,
    );

    switch (highestImportance) {
      case ImportanceLevel.low:
        return Colors.green.withValues(alpha: 0.6);
      case ImportanceLevel.medium:
        return Colors.orange.withValues(alpha: 0.6);
      case ImportanceLevel.high:
        return Colors.red.withValues(alpha: 0.6);
    }
  }

  void _showTitlesPopup(
    BuildContext context,
    DateTime date,
    List<Reminder> reminders,
    List<JournalEntry> entries,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.1),
                  Colors.white.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1.5,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Material(
                    color: Colors.transparent,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${date.day} ${_getMonthName(date.month)} ${date.year}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.white70,
                              ),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (entries.isNotEmpty) ...[
                          const Text(
                            'Journals',
                            style: TextStyle(
                              color: Colors.deepPurpleAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...entries.map(
                            (entry) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: InkWell(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  context.push('/home/entry/${entry.id}');
                                },
                                child: Row(
                                  children: [
                                    Text(
                                      entry.mood.emoji,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.title.isEmpty
                                            ? 'Untitled Journal'
                                            : entry.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (reminders.isNotEmpty) ...[
                          const Text(
                            'Reminders',
                            style: TextStyle(
                              color: Colors.orangeAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...reminders.map(
                            (reminder) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Row(
                                children: [
                                  _getImportanceIndicator(
                                    reminder.importanceLevel,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      reminder.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  Widget _getImportanceIndicator(ImportanceLevel level) {
    Color color;
    switch (level) {
      case ImportanceLevel.low:
        color = Colors.green;
        break;
      case ImportanceLevel.medium:
        color = Colors.orange;
        break;
      case ImportanceLevel.high:
        color = Colors.red;
        break;
    }
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth =
        DateTime(
          widget.selectedDate.year,
          widget.selectedDate.month + 1,
          0,
        ).day;
    final dates = List.generate(
      daysInMonth,
      (index) => DateTime(
        widget.selectedDate.year,
        widget.selectedDate.month,
        index + 1,
      ),
    );

    return SizedBox(
      height: 100,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: dates.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = date.day == widget.selectedDate.day;
          final color = _getColorForDate(date);

          final remindersForDate =
              widget.monthlyReminders
                  .where(
                    (r) =>
                        r.date.year == date.year &&
                        r.date.month == date.month &&
                        r.date.day == date.day,
                  )
                  .toList();

          final entriesForDate =
              widget.monthlyEntries
                  .where(
                    (e) =>
                        e.date.year == date.year &&
                        e.date.month == date.month &&
                        e.date.day == date.day,
                  )
                  .toList();

          final totalCount = remindersForDate.length + entriesForDate.length;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () => widget.onDateSelected(date),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(right: 12, top: 8, bottom: 4),
                  width: 60,
                  decoration: BoxDecoration(
                    color:
                        isSelected
                            ? Colors.white.withValues(alpha: 0.15)
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color:
                          isSelected
                              ? Colors.white.withValues(alpha: 0.15)
                              : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _getWeekdayString(date.weekday),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${date.day}',
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white54,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (totalCount > 0)
                Positioned(
                  right: 4,
                  top: 2,
                  child: GestureDetector(
                    onTap:
                        () => _showTitlesPopup(
                          context,
                          date,
                          remindersForDate,
                          entriesForDate,
                        ),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.deepPurpleAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF1E1E2C),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.deepPurpleAccent.withValues(
                              alpha: 0.4,
                            ),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 20,
                        minHeight: 20,
                      ),
                      child: Center(
                        child: Text(
                          '$totalCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _getWeekdayString(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }
}
