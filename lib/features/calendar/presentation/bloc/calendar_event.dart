import 'package:equatable/equatable.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';

sealed class CalendarEvent extends Equatable {
  const CalendarEvent();

  @override
  List<Object?> get props => [];
}

class LoadCalendarData extends CalendarEvent {
  const LoadCalendarData({required this.month});

  final DateTime month;

  @override
  List<Object?> get props => [month];
}

class SelectDate extends CalendarEvent {
  const SelectDate(this.date);

  final DateTime date;

  @override
  List<Object?> get props => [date];
}

class AddReminderEvent extends CalendarEvent {
  const AddReminderEvent(this.reminder);

  final Reminder reminder;

  @override
  List<Object?> get props => [reminder];
}

class DeleteReminderEvent extends CalendarEvent {
  const DeleteReminderEvent(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
