import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/features/calendar/domain/usecases/delete_reminder.dart';
import 'package:rojnivis/features/calendar/domain/usecases/get_all_reminders.dart';
import 'reminders_event.dart';
import 'reminders_state.dart';

@injectable
class RemindersBloc extends Bloc<RemindersEvent, RemindersState> {
  RemindersBloc({
    required this.getAllReminders,
    required this.deleteReminder,
  }) : super(const RemindersInitial()) {
    on<LoadAllReminders>(_onLoadAllReminders);
    on<DeleteReminderFromList>(_onDeleteReminder);
  }

  final GetAllReminders getAllReminders;
  final DeleteReminder deleteReminder;

  Future<void> _onLoadAllReminders(
    LoadAllReminders event,
    Emitter<RemindersState> emit,
  ) async {
    emit(const RemindersLoading());

    final result = await getAllReminders();

    result.fold((failure) => emit(RemindersFailure(failure)), (reminders) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tomorrow = today.add(const Duration(days: 1));

      final pastReminders = reminders.where((r) => r.date.isBefore(today)).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

      final todayReminders = reminders.where((r) => r.date.isAfter(today.subtract(const Duration(milliseconds: 1))) && r.date.isBefore(tomorrow)).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      final upcomingReminders = reminders.where((r) => r.date.isAfter(tomorrow.subtract(const Duration(milliseconds: 1)))).toList()
        ..sort((a, b) => a.date.compareTo(b.date));

      emit(
        RemindersLoaded(
          pastReminders: pastReminders,
          todayReminders: todayReminders,
          upcomingReminders: upcomingReminders,
        ),
      );
    });
  }

  Future<void> _onDeleteReminder(
    DeleteReminderFromList event,
    Emitter<RemindersState> emit,
  ) async {
    final result = await deleteReminder(DeleteReminderParams(id: event.id));
    
    result.fold(
      (failure) => emit(RemindersFailure(failure)),
      (_) => add(const LoadAllReminders()),
    );
  }
}
