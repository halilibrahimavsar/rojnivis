part of 'journal_bloc.dart';

enum JournalViewMode { list, grid, calendar }

/// Base class for all journal states.
sealed class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any operation.
class JournalInitial extends JournalState {
  const JournalInitial();
}

/// State when loading journal entries.
class JournalLoading extends JournalState {
  const JournalLoading();
}

/// State when journal entries are successfully loaded.
class JournalLoaded extends JournalState {
  final JournalFilter filter;
  final List<JournalEntry> entries;
  final JournalViewMode viewMode;

  const JournalLoaded({
    required this.entries,
    this.filter = const JournalFilter(),
    this.viewMode = JournalViewMode.list,
  });

  JournalLoaded copyWith({
    List<JournalEntry>? entries,
    JournalFilter? filter,
    JournalViewMode? viewMode,
  }) {
    return JournalLoaded(
      entries: entries ?? this.entries,
      filter: filter ?? this.filter,
      viewMode: viewMode ?? this.viewMode,
    );
  }

  @override
  List<Object?> get props => [entries, filter, viewMode];
}

/// State when an error occurs during loading.
class JournalError extends JournalState {
  final String message;
  final Object? error;

  const JournalError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}

/// State when an action (add/update/delete) is in progress.
class JournalActionInProgress extends JournalState {
  const JournalActionInProgress();
}

/// State when an action (add/update/delete) fails.
class JournalActionError extends JournalState {
  final String message;
  final Object? error;

  const JournalActionError({required this.message, this.error});

  @override
  List<Object?> get props => [message, error];
}
