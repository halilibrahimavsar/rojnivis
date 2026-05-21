import 'package:equatable/equatable.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';

sealed class CalendarState extends Equatable {
  const CalendarState();

  @override
  List<Object?> get props => [];
}

class CalendarInitial extends CalendarState {
  const CalendarInitial();
}

class CalendarLoading extends CalendarState {
  const CalendarLoading();
}

class CalendarLoaded extends CalendarState {
  const CalendarLoaded({
    required this.selectedDate,
    required this.reminders,
    required this.entries,
    required this.monthlyReminders,
    required this.monthlyEntries,
  });

  final DateTime selectedDate;
  final List<Reminder> reminders;
  final List<JournalEntry> entries;
  final List<Reminder> monthlyReminders;
  final List<JournalEntry> monthlyEntries;

  CalendarLoaded copyWith({
    DateTime? selectedDate,
    List<Reminder>? reminders,
    List<JournalEntry>? entries,
    List<Reminder>? monthlyReminders,
    List<JournalEntry>? monthlyEntries,
  }) {
    return CalendarLoaded(
      selectedDate: selectedDate ?? this.selectedDate,
      reminders: reminders ?? this.reminders,
      entries: entries ?? this.entries,
      monthlyReminders: monthlyReminders ?? this.monthlyReminders,
      monthlyEntries: monthlyEntries ?? this.monthlyEntries,
    );
  }

  @override
  List<Object?> get props => [
    selectedDate,
    reminders,
    entries,
    monthlyReminders,
    monthlyEntries,
  ];
}

class CalendarFailure extends CalendarState {
  const CalendarFailure(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => [failure];
}
