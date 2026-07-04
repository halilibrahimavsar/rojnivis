import 'package:equatable/equatable.dart';

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
