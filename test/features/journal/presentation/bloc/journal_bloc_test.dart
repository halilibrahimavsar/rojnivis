import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rojnivis/features/journal/data/models/journal_entry_model.dart';
import 'package:rojnivis/features/journal/domain/models/filter_model.dart';
import 'package:rojnivis/features/journal/domain/usecases/add_entry.dart';
import 'package:rojnivis/features/journal/domain/usecases/delete_entry.dart';
import 'package:rojnivis/features/journal/domain/usecases/get_entries.dart';
import 'package:rojnivis/features/journal/domain/usecases/search_entries.dart';
import 'package:rojnivis/features/journal/presentation/bloc/journal_bloc.dart';

class MockGetEntries extends Mock implements GetEntries {}

class MockAddEntry extends Mock implements AddEntry {}

class MockSearchEntries extends Mock implements SearchEntries {}

class MockDeleteEntry extends Mock implements DeleteEntry {}

void main() {
  late MockGetEntries mockGetEntries;
  late MockAddEntry mockAddEntry;
  late MockSearchEntries mockSearchEntries;
  late MockDeleteEntry mockDeleteEntry;

  final testEntry = JournalEntryModel(
    id: 'entry-1',
    title: 'Test Entry',
    content: 'Test content',
    date: DateTime(2026, 1, 1),
    moodIndex: 0,
    categoryId: 'general',
  );

  final testEntries = [testEntry];
  const testFilter = JournalFilter(query: 'test');

  setUp(() {
    mockGetEntries = MockGetEntries();
    mockAddEntry = MockAddEntry();
    mockSearchEntries = MockSearchEntries();
    mockDeleteEntry = MockDeleteEntry();
  });

  setUpAll(() {
    registerFallbackValue(testEntry);
    registerFallbackValue(testFilter);
  });

  JournalBloc buildBloc() => JournalBloc(
        mockGetEntries,
        mockAddEntry,
        mockSearchEntries,
        mockDeleteEntry,
      );

  group('JournalBloc', () {
    test('initial state is JournalInitial', () {
      expect(buildBloc().state, const JournalInitial());
    });

    group('LoadJournalEntries', () {
      blocTest<JournalBloc, JournalState>(
        'emits [JournalLoading, JournalLoaded] when loading succeeds',
        setUp: () {
          when(() => mockGetEntries()).thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadJournalEntries()),
        expect: () => [
          const JournalLoading(),
          JournalLoaded(entries: testEntries),
        ],
      );

      blocTest<JournalBloc, JournalState>(
        'emits [JournalLoading, JournalError] when loading fails',
        setUp: () {
          when(() => mockGetEntries()).thenThrow(Exception('Load failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadJournalEntries()),
        expect: () => [
          const JournalLoading(),
          isA<JournalError>(),
        ],
      );
    });

    group('UpsertEntryRequested', () {
      blocTest<JournalBloc, JournalState>(
        'calls addEntry and reloads entries on success',
        setUp: () {
          when(() => mockAddEntry(any())).thenAnswer((_) async {});
          when(() => mockGetEntries()).thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(UpsertEntryRequested(entry: testEntry)),
        verify: (_) {
          verify(() => mockAddEntry(testEntry)).called(1);
        },
      );

      blocTest<JournalBloc, JournalState>(
        'emits JournalActionError when upsert fails',
        setUp: () {
          when(() => mockAddEntry(any()))
              .thenThrow(Exception('Upsert failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(UpsertEntryRequested(entry: testEntry)),
        expect: () => [
          const JournalActionInProgress(),
          isA<JournalActionError>(),
        ],
      );
    });

    group('DeleteEntryRequested', () {
      blocTest<JournalBloc, JournalState>(
        'calls deleteEntry and reloads entries on success',
        setUp: () {
          when(() => mockDeleteEntry(any())).thenAnswer((_) async {});
          when(() => mockGetEntries()).thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const DeleteEntryRequested(entryId: 'entry-1')),
        verify: (_) {
          verify(() => mockDeleteEntry('entry-1')).called(1);
        },
      );
    });

    group('SearchRequested', () {
      blocTest<JournalBloc, JournalState>(
        'emits [JournalLoading, JournalLoaded] when search succeeds',
        setUp: () {
          when(() => mockSearchEntries(any()))
              .thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const SearchRequested(filter: testFilter)),
        expect: () => [
          const JournalLoading(),
          JournalLoaded(entries: testEntries, filter: testFilter),
        ],
      );

      blocTest<JournalBloc, JournalState>(
        'reloads all entries when query is empty',
        setUp: () {
          when(() => mockGetEntries()).thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const SearchRequested(filter: JournalFilter())),
        expect: () => [
          const JournalLoading(),
          JournalLoaded(entries: testEntries),
        ],
      );
    });

    group('ClearSearch', () {
      blocTest<JournalBloc, JournalState>(
        'reloads all entries when search is cleared',
        setUp: () {
          when(() => mockGetEntries()).thenAnswer((_) async => testEntries);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const ClearSearch()),
        expect: () => [
          const JournalLoading(),
          JournalLoaded(entries: testEntries),
        ],
      );
    });
  });
}
