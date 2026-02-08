part of 'journal_bloc.dart';

abstract class JournalState extends Equatable {
  const JournalState();

  @override
  List<Object> get props => [];
}

class JournalInitial extends JournalState {}

class JournalLoading extends JournalState {}

class JournalLoaded extends JournalState {
  final List<JournalEntry> entries;

  const JournalLoaded(this.entries);

  @override
  List<Object> get props => [entries];
}

class JournalError extends JournalState {
  final String message;

  const JournalError(this.message);

  @override
  List<Object> get props => [message];
}
