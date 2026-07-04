import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/calendar_bloc.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/calendar_event.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/calendar_state.dart';
import 'package:rojnivis/features/calendar/presentation/widgets/daily_timeline_view.dart';
import 'package:rojnivis/features/calendar/presentation/widgets/horizontal_date_carousel.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CalendarBloc, CalendarState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: Container(
            color: Colors.transparent,
            child: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Calendar',
                          style: Theme.of(
                            context,
                          ).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.format_list_bulleted, color: Colors.white),
                          onPressed: () async {
                            await context.push('/home/calendar/reminders');
                            if (context.mounted) {
                              final currentState = context.read<CalendarBloc>().state;
                              if (currentState is CalendarLoaded) {
                                context.read<CalendarBloc>().add(LoadCalendarData(month: currentState.selectedDate));
                              }
                            }
                          },
                          tooltip: 'Manage Reminders',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state is CalendarLoading ||
                            state is CalendarInitial) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (state is CalendarFailure) {
                          return const Center(
                            child: Text(
                              'Failed to load data',
                              style: TextStyle(color: Colors.red),
                            ),
                          );
                        }
                        if (state is CalendarLoaded) {
                          return Column(
                            children: [
                              HorizontalDateCarousel(
                                selectedDate: state.selectedDate,
                                monthlyReminders: state.monthlyReminders,
                                monthlyEntries: state.monthlyEntries,
                                onDateSelected: (date) {
                                  context.read<CalendarBloc>().add(
                                    SelectDate(date),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              Expanded(
                                child: DailyTimelineView(
                                  entries: state.entries,
                                  reminders: state.reminders,
                                  onDeleteReminder: (reminder) {
                                    context.read<CalendarBloc>().add(
                                      DeleteReminderEvent(reminder.id),
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
