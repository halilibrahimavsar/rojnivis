import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/usecases/add_entry.dart';
import '../../domain/usecases/get_entries.dart';
import '../../domain/usecases/search_entries.dart';
import '../../domain/usecases/delete_entry.dart';

part 'journal_event.dart';
part 'journal_state.dart';

@injectable
class JournalBloc extends Bloc<JournalEvent, JournalState> {
  final GetEntries _getEntries;
  final AddEntry _addEntry;
  final SearchEntries _searchEntries;
  final DeleteEntry _deleteEntry;

  JournalBloc(
    this._getEntries,
    this._addEntry,
    this._searchEntries,
    this._deleteEntry,
  ) : super(JournalInitial()) {
    on<LoadJournalEntries>(_onLoadJournalEntries);
    on<AddJournalEntryEvent>(_onAddJournalEntry);
    on<SearchJournalEntries>(_onSearchJournalEntries);
    on<DeleteJournalEntryEvent>(_onDeleteJournalEntry);
  }

  Future<void> _onLoadJournalEntries(
    LoadJournalEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());
    try {
      final entries = await _getEntries();
      emit(JournalLoaded(entries));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onAddJournalEntry(
    AddJournalEntryEvent event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _addEntry(event.entry);
      add(LoadJournalEntries());
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onSearchJournalEntries(
    SearchJournalEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(JournalLoading());
    try {
      final entries = await _searchEntries(event.query);
      emit(JournalLoaded(entries));
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }

  Future<void> _onDeleteJournalEntry(
    DeleteJournalEntryEvent event,
    Emitter<JournalState> emit,
  ) async {
    try {
      await _deleteEntry(event.entryId);
      add(LoadJournalEntries());
    } catch (e) {
      emit(JournalError(e.toString()));
    }
  }
}
