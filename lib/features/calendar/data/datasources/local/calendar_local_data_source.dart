import 'package:injectable/injectable.dart';
import 'package:rojnivis/features/calendar/data/models/reminder_dto.dart';

abstract class CalendarLocalDataSource {
  Future<List<ReminderDto>> getReminders(DateTime startDate, DateTime endDate);
  Future<void> addReminder(ReminderDto reminder);
  Future<void> deleteReminder(String id);
}

@LazySingleton(as: CalendarLocalDataSource)
class CalendarLocalDataSourceImpl implements CalendarLocalDataSource {
  // In a real app, use Hive or another local database.
  // Using an in-memory list for now, as it's a new feature.
  final List<ReminderDto> _reminders = [];

  @override
  Future<List<ReminderDto>> getReminders(
    DateTime startDate,
    DateTime endDate,
  ) async {
    return _reminders.where((reminder) {
      return reminder.date.isAfter(startDate) &&
          reminder.date.isBefore(endDate);
    }).toList();
  }

  @override
  Future<void> addReminder(ReminderDto reminder) async {
    final index = _reminders.indexWhere((r) => r.id == reminder.id);
    if (index >= 0) {
      _reminders[index] = reminder;
    } else {
      _reminders.add(reminder);
    }
  }

  @override
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
  }
}
