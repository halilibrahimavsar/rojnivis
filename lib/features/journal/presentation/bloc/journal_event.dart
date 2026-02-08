part of 'journal_bloc.dart';

/// Base class for all journal events.
sealed class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load all journal entries.
class LoadJournalEntries extends JournalEvent {
  const LoadJournalEntries();
}

/// Event to add or update a journal entry.
class UpsertEntryRequested extends JournalEvent {
  final JournalEntryModel entry;

  const UpsertEntryRequested({required this.entry});

  @override
  List<Object?> get props => [entry];
}

/// Event to delete a journal entry.
class DeleteEntryRequested extends JournalEvent {
  final String entryId;

  const DeleteEntryRequested({required this.entryId});

  @override
  List<Object?> get props => [entryId];
}

/// Event to search journal entries.
class SearchRequested extends JournalEvent {
  final JournalFilter filter;

  const SearchRequested({required this.filter});

  @override
  List<Object?> get props => [filter];
}

/// Event to clear the search query.
class ClearSearch extends JournalEvent {
  const ClearSearch();
}
