import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/features/calendar/domain/usecases/add_reminder.dart';
import 'package:rojnivis/features/calendar/domain/usecases/delete_reminder.dart';
import 'package:rojnivis/features/calendar/domain/usecases/get_reminders.dart';
import 'package:rojnivis/features/journal/domain/usecases/get_entries.dart';
import 'calendar_event.dart';
import 'calendar_state.dart';

@injectable
class CalendarBloc extends Bloc<CalendarEvent, CalendarState> {
  CalendarBloc({
    required this.getReminders,
    required this.getEntries,
    required this.addReminder,
    required this.deleteReminder,
  }) : super(const CalendarInitial()) {
    on<LoadCalendarData>(_onLoadCalendarData);
    on<SelectDate>(_onSelectDate);
    on<AddReminderEvent>(_onAddReminder);
    on<DeleteReminderEvent>(_onDeleteReminder);
  }

  final GetReminders getReminders;
  final GetEntries getEntries;
  final AddReminder addReminder;
  final DeleteReminder deleteReminder;

  Future<void> _onLoadCalendarData(
    LoadCalendarData event,
    Emitter<CalendarState> emit,
  ) async {
    emit(const CalendarLoading());

    final startDate = DateTime(event.month.year, event.month.month, 1);
    final endDate = DateTime(event.month.year, event.month.month + 1, 0);

    final remindersResult = await getReminders(
      GetRemindersParams(startDate: startDate, endDate: endDate),
    );
    final entriesResult = await getEntries();

    remindersResult.fold((failure) => emit(CalendarFailure(failure)), (
      reminders,
    ) {
      if (entriesResult.$1 != null) {
        emit(CalendarFailure(entriesResult.$1!));
      } else {
        final entries = entriesResult.$2!;
        final selectedDate = DateTime(
          event.month.year,
          event.month.month,
          event.month.day,
        );

        final dailyReminders =
            reminders.where((r) {
              return r.date.year == selectedDate.year &&
                  r.date.month == selectedDate.month &&
                  r.date.day == selectedDate.day;
            }).toList();

        final dailyEntries =
            entries.where((e) {
              return e.date.year == selectedDate.year &&
                  e.date.month == selectedDate.month &&
                  e.date.day == selectedDate.day;
            }).toList();

        final monthlyEntries =
            entries.where((e) {
              return e.date.year == event.month.year &&
                  e.date.month == event.month.month;
            }).toList();

        emit(
          CalendarLoaded(
            selectedDate: selectedDate,
            reminders: dailyReminders,
            entries: dailyEntries,
            monthlyReminders: reminders,
            monthlyEntries: monthlyEntries,
          ),
        );
      }
    });
  }

  Future<void> _onSelectDate(
    SelectDate event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final selectedDate = DateTime(
        event.date.year,
        event.date.month,
        event.date.day,
      );

      if (selectedDate.month != currentState.selectedDate.month ||
          selectedDate.year != currentState.selectedDate.year) {
        add(LoadCalendarData(month: selectedDate));
        return;
      }

      final entriesResult = await getEntries();
      if (entriesResult.$1 != null) {
        emit(CalendarFailure(entriesResult.$1!));
      } else {
        final entries = entriesResult.$2!;
        final dailyReminders =
            currentState.monthlyReminders.where((r) {
              return r.date.year == selectedDate.year &&
                  r.date.month == selectedDate.month &&
                  r.date.day == selectedDate.day;
            }).toList();

        final dailyEntries =
            entries.where((e) {
              return e.date.year == selectedDate.year &&
                  e.date.month == selectedDate.month &&
                  e.date.day == selectedDate.day;
            }).toList();

        final monthlyEntries =
            entries.where((e) {
              return e.date.year == selectedDate.year &&
                  e.date.month == selectedDate.month;
            }).toList();

        emit(
          currentState.copyWith(
            selectedDate: selectedDate,
            reminders: dailyReminders,
            entries: dailyEntries,
            monthlyEntries: monthlyEntries,
          ),
        );
      }
    }
  }

  Future<void> _onAddReminder(
    AddReminderEvent event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final result = await addReminder(
        AddReminderParams(reminder: event.reminder),
      );
      result.fold((failure) => emit(CalendarFailure(failure)), (_) {
        add(LoadCalendarData(month: currentState.selectedDate));
      });
    }
  }

  Future<void> _onDeleteReminder(
    DeleteReminderEvent event,
    Emitter<CalendarState> emit,
  ) async {
    final currentState = state;
    if (currentState is CalendarLoaded) {
      final result = await deleteReminder(DeleteReminderParams(id: event.id));
      result.fold((failure) => emit(CalendarFailure(failure)), (_) {
        add(LoadCalendarData(month: currentState.selectedDate));
      });
    }
  }
}
