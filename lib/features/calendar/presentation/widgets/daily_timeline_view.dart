import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';
import 'package:go_router/go_router.dart';

class DailyTimelineView extends StatelessWidget {
  const DailyTimelineView({
    super.key,
    required this.entries,
    required this.reminders,
    this.onDeleteReminder,
  });

  final List<JournalEntry> entries;
  final List<Reminder> reminders;
  final ValueChanged<Reminder>? onDeleteReminder;

  @override
  Widget build(BuildContext context) {
    final items = <dynamic>[...reminders, ...entries];

    // Sort items by date (assuming we want chronologically)
    items.sort((a, b) {
      final DateTime dateA = a is Reminder ? a.date : (a as JournalEntry).date;
      final DateTime dateB = b is Reminder ? b.date : (b as JournalEntry).date;
      return dateA.compareTo(dateB);
    });

    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No events or entries for this day.',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        if (item is Reminder) {
          return _buildReminderCard(item);
        } else if (item is JournalEntry) {
          return GestureDetector(
            onTap: () => context.push('/home/entry/${item.id}'),
            child: _buildEntryCard(item),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildGlassCard({required Widget child, required Color borderColor}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: borderColor.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }

  Widget _buildReminderCard(Reminder reminder) {
    Color importanceColor;
    switch (reminder.importanceLevel) {
      case ImportanceLevel.low:
        importanceColor = Colors.green;
        break;
      case ImportanceLevel.medium:
        importanceColor = Colors.orange;
        break;
      case ImportanceLevel.high:
        importanceColor = Colors.red;
        break;
    }

    return _buildGlassCard(
      borderColor: importanceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.notifications_active,
                color: importanceColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  reminder.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '${reminder.date.hour.toString().padLeft(2, '0')}:${reminder.date.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.white70),
              ),
              if (onDeleteReminder != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.white54,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => onDeleteReminder!(reminder),
                ),
              ],
            ],
          ),
          if (reminder.description != null &&
              reminder.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              reminder.description!,
              style: const TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntryCard(JournalEntry entry) {
    return _buildGlassCard(
      borderColor: Colors.blueAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.book, color: Colors.blueAccent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.title.isNotEmpty ? entry.title : 'Journal Entry',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(entry.mood.emoji, style: const TextStyle(fontSize: 20)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            entry.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
