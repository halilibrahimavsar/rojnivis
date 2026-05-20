import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_filter.dart';

import '../../../../core/errors/error_handler.dart';
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
    on<ChangeViewModeRequested>(_onChangeViewMode);
  }

  void _onChangeViewMode(
    ChangeViewModeRequested event,
    Emitter<JournalState> emit,
  ) {
    if (state is JournalLoaded) {
      final loadedState = state as JournalLoaded;
      emit(loadedState.copyWith(viewMode: event.viewMode));
    }
  }

  /// Handles loading all journal entries.
  Future<void> _onLoad(
    LoadJournalEntries event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalLoading());
    final (failure, entries) = await _getEntries();

    if (failure != null) {
      ErrorHandler.logError(failure, context: 'JournalBloc._onLoad');
      emit(JournalError(message: failure.message));
    } else {
      emit(JournalLoaded(entries: entries ?? []));
    }
  }

  /// Handles adding or updating a journal entry.
  Future<void> _onUpsert(
    UpsertEntryRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalActionInProgress());
    final (failure, _) = await _addEntry(event.entry);

    if (failure != null) {
      ErrorHandler.logError(failure, context: 'JournalBloc._onUpsert');
      emit(JournalActionError(message: failure.message));
    } else {
      add(const LoadJournalEntries());
    }
  }

  /// Handles deleting a journal entry.
  Future<void> _onDelete(
    DeleteEntryRequested event,
    Emitter<JournalState> emit,
  ) async {
    emit(const JournalActionInProgress());
    final (failure, _) = await _deleteEntry(event.entryId);

    if (failure != null) {
      ErrorHandler.logError(failure, context: 'JournalBloc._onDelete');
      emit(JournalActionError(message: failure.message));
    } else {
      add(const LoadJournalEntries());
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
    final (failure, entries) = await _searchEntries(filter);

    if (failure != null) {
      ErrorHandler.logError(failure, context: 'JournalBloc._onSearch');
      emit(JournalError(message: failure.message));
    } else {
      emit(JournalLoaded(entries: entries ?? [], filter: filter));
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
