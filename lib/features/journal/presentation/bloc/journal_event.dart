part of 'journal_bloc.dart';

abstract class JournalEvent extends Equatable {
  const JournalEvent();

  @override
  List<Object> get props => [];
}

class LoadJournalEntries extends JournalEvent {}

class AddJournalEntryEvent extends JournalEvent {
  final JournalEntry entry;

  const AddJournalEntryEvent(this.entry);

  @override
  List<Object> get props => [entry];
}

class SearchJournalEntries extends JournalEvent {
  final String query;

  const SearchJournalEntries(this.query);

  @override
  List<Object> get props => [query];
}

class DeleteJournalEntryEvent extends JournalEvent {
  final String entryId;

  const DeleteJournalEntryEvent(this.entryId);

  @override
  List<Object> get props => [entryId];
}
