import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/core/constants/app_constants.dart';
import 'package:rojnivis/features/reminders/data/models/reminder_dto.dart';

abstract class RemindersLocalDataSource {
  Future<List<ReminderDto>> getReminders(DateTime startDate, DateTime endDate);
  Future<List<ReminderDto>> getAllReminders();
  Future<void> addReminder(ReminderDto reminder);
  Future<void> deleteReminder(String id);
}

@LazySingleton(as: RemindersLocalDataSource)
class RemindersLocalDataSourceImpl implements RemindersLocalDataSource {
  Box<ReminderDto> get _box => Hive.box<ReminderDto>(StorageKeys.remindersBox);

  @override
  Future<List<ReminderDto>> getReminders(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59, 999);

    return _box.values.where((reminder) {
      return reminder.date.isAfter(start.subtract(const Duration(milliseconds: 1))) &&
          reminder.date.isBefore(end.add(const Duration(milliseconds: 1)));
    }).toList();
  }

  @override
  Future<List<ReminderDto>> getAllReminders() async {
    return _box.values.toList();
  }

  @override
  Future<void> addReminder(ReminderDto reminder) async {
    await _box.put(reminder.id, reminder);
  }

  @override
  Future<void> deleteReminder(String id) async {
    await _box.delete(id);
  }
}
