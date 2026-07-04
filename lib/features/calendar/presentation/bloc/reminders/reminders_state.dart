import 'package:equatable/equatable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';

sealed class RemindersState extends Equatable {
  const RemindersState();

  @override
  List<Object?> get props => [];
}

final class RemindersInitial extends RemindersState {
  const RemindersInitial();
}

final class RemindersLoading extends RemindersState {
  const RemindersLoading();
}

final class RemindersLoaded extends RemindersState {
  const RemindersLoaded({
    required this.pastReminders,
    required this.todayReminders,
    required this.upcomingReminders,
  });

  final List<Reminder> pastReminders;
  final List<Reminder> todayReminders;
  final List<Reminder> upcomingReminders;

  @override
  List<Object?> get props => [pastReminders, todayReminders, upcomingReminders];
}

final class RemindersFailure extends RemindersState {
  const RemindersFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
