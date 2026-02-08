import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/features/journal/domain/models/filter_model.dart';

import '../../../../core/errors/error_handler.dart';
import '../../data/models/journal_entry_model.dart';
import '../../domain/usecases/add_entry.dart';
import '../../domain/usecases/delete_entry.dart';
import '../../domain/usecases/get_entries.dart';
import '../../domain/usecases/search_entries.dart';

part 'journal_event.dart';
part 'journal_state.dart';

/// BLoC responsible for managing journal entries state.
///
/// Handles loading, adding, updating, deleting, and searching journal entries.
/// Uses the BLoC pattern to separate business logic from UI.
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
  ) : super(const JournalInitial()) {
    on<LoadJournalEntries>(_onLoad);
    on<UpsertEntryRequested>(_onUpsert);
    on<DeleteEntryRequested>(_onDelete);
    on<SearchRequested>(_onSearch);
    on<ClearSearch>(_onClearSearch);
  }

  /// Handles loading all journal entries.
  Future<void> _onLoad(
    LoadJournalEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());
    try {
      final entries = await _getEntries();
      emit(JournalLoaded(entries: entries));
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'JournalBloc._onLoad',
      );
      emit(JournalError(message: error.toErrorMessage(), error: error));
    }
  }

  /// Handles adding or updating a journal entry.
  Future<void> _onUpsert(
    UpsertEntryRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalActionInProgress());
    try {
      await _addEntry(event.entry);
      add(const LoadJournalEntries());
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'JournalBloc._onUpsert',
      );
      emit(JournalActionError(message: error.toErrorMessage(), error: error));
    }
  }

  /// Handles deleting a journal entry.
  Future<void> _onDelete(
    DeleteEntryRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalActionInProgress());
    try {
      await _deleteEntry(event.entryId);
      add(const LoadJournalEntries());
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'JournalBloc._onDelete',
      );
      emit(JournalActionError(message: error.toErrorMessage(), error: error));
    }
  }

  /// Handles searching journal entries.
  Future<void> _onSearch(
    SearchRequested event,
    Emitter<JournalState> emit,
  ) async {
    final filter = event.filter;
    if (filter.isEmpty) {
      add(const LoadJournalEntries());
      return;
    }

    emit(const JournalLoading());
    try {
      final entries = await _searchEntries(filter);
      emit(JournalLoaded(entries: entries, filter: filter));
    } catch (error, stackTrace) {
      ErrorHandler.logError(
        error,
        stackTrace: stackTrace,
        context: 'JournalBloc._onSearch',
      );
      emit(JournalError(message: error.toErrorMessage(), error: error));
    }
  }

  /// Handles clearing the search query.
  Future<void> _onClearSearch(
    ClearSearch event,
    Emitter<JournalState> emit,
  ) async {
    add(const LoadJournalEntries());
  }
}
