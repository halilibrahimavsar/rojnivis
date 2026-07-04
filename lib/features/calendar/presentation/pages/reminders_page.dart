import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:rojnivis/core/widgets/glass_overlays.dart';
import 'package:rojnivis/features/calendar/domain/entities/reminder.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/reminders/reminders_bloc.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/reminders/reminders_event.dart';
import 'package:rojnivis/features/calendar/presentation/bloc/reminders/reminders_state.dart';

class RemindersPage extends StatelessWidget {
  const RemindersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GetIt.I<RemindersBloc>()..add(const LoadAllReminders()),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocBuilder<RemindersBloc, RemindersState>(
                  builder: (context, state) {
                    if (state is RemindersLoading || state is RemindersInitial) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state is RemindersFailure) {
                      return Center(
                        child: Text(
                          'Failed to load reminders: ${state.failure.message}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }
                    if (state is RemindersLoaded) {
                      final allEmpty = state.pastReminders.isEmpty &&
                          state.todayReminders.isEmpty &&
                          state.upcomingReminders.isEmpty;

                      if (allEmpty) {
                        return _buildEmptyState(context);
                      }

                      return ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        children: [
                          if (state.todayReminders.isNotEmpty)
                            _buildSection('Today', state.todayReminders, context),
                          if (state.upcomingReminders.isNotEmpty)
                            _buildSection('Upcoming', state.upcomingReminders, context),
                          if (state.pastReminders.isNotEmpty)
                            _buildSection('Past', state.pastReminders, context, isPast: true),
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
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Reminders',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Reminder> reminders, BuildContext context, {bool isPast = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: isPast ? 0.5 : 0.9),
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        ...reminders.map((reminder) => _buildReminderCard(reminder, context, isPast)),
      ],
    );
  }

  Widget _buildReminderCard(Reminder reminder, BuildContext context, bool isPast) {
    final color = _getImportanceColor(reminder.importanceLevel);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Dismissible(
        key: Key(reminder.id),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
        ),
        onDismissed: (_) {
          context.read<RemindersBloc>().add(DeleteReminderFromList(reminder.id));
        },
        child: GlassContainer(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Opacity(
            opacity: isPast ? 0.6 : 1.0,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.5),
                        blurRadius: 8,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (reminder.description != null && reminder.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          reminder.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat('dd MMM yyyy, HH:mm').format(reminder.date),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: Colors.white.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No reminders yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your upcoming reminders will appear here',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
          ),
        ],
      ),
    );
  }

  Color _getImportanceColor(ImportanceLevel level) {
    switch (level) {
      case ImportanceLevel.high:
        return Colors.redAccent;
      case ImportanceLevel.medium:
        return Colors.orangeAccent;
      case ImportanceLevel.low:
        return Colors.greenAccent;
    }
  }
}
