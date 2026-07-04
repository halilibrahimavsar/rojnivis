import 'package:equatable/equatable.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';

sealed class RemindersEvent extends Equatable {
  const RemindersEvent();

  @override
  List<Object?> get props => [];
}

final class LoadAllReminders extends RemindersEvent {
  const LoadAllReminders();
}

final class DeleteReminderFromList extends RemindersEvent {
  const DeleteReminderFromList(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}

final class AddReminderToList extends RemindersEvent {
  const AddReminderToList(this.reminder);

  final Reminder reminder;

  @override
  List<Object?> get props => [reminder];
}
