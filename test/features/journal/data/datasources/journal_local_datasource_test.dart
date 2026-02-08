import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:hive_test/hive_test.dart';
import 'package:rojnivis/features/journal/data/datasources/journal_local_datasource.dart';
import 'package:rojnivis/features/journal/data/models/journal_entry_model.dart';
import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';
import 'package:rojnivis/features/journal/domain/models/filter_model.dart';

void main() {
  late JournalLocalDataSourceImpl dataSource;
  late Box<JournalEntryModel> box;

  setUp(() async {
    await setUpTestHive();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(JournalEntryModelAdapter());
      Hive.registerAdapter(MoodAdapter());
    }
    box = await Hive.openBox<JournalEntryModel>(JournalEntryModel.boxName);
    dataSource = JournalLocalDataSourceImpl();
  });

  tearDown(() async {
    await tearDownTestHive();
  });

  final date1 = DateTime(2023, 1, 1);
  final date2 = DateTime(2023, 1, 2);
  final date3 = DateTime(2023, 1, 3);

  final entry1 = JournalEntryModel(
    id: '1',
    title: 'Entry 1',
    content: 'Content 1',
    date: date1,
    mood: Mood.happy,
    tags: ['tag1'],
    categoryId: 'cat1',
    attachmentPaths: [],
  );

  final entry2 = JournalEntryModel(
    id: '2',
    title: 'Entry 2',
    content: 'Content 2',
    date: date2,
    mood: Mood.sad,
    tags: ['tag2'],
    categoryId: 'cat2',
    attachmentPaths: [],
  );

  final entry3 = JournalEntryModel(
    id: '3',
    title: 'Entry 3',
    content: 'Content 3',
    date: date3,
    mood: Mood.neutral,
    tags: ['tag1', 'tag3'],
    categoryId: 'cat1',
    attachmentPaths: [],
  );

  Future<void> seedEntries() async {
    await box.put(entry1.id, entry1);
    await box.put(entry2.id, entry2);
    await box.put(entry3.id, entry3);
  }

  group('searchEntries', () {
    test('returns all entries when filter is empty', () async {
      await seedEntries();
      final result = dataSource.searchEntries(const JournalFilter());
      expect(result.length, 3);
    });

    test('filters by query', () async {
      await seedEntries();
      final result = dataSource.searchEntries(
        const JournalFilter(query: 'Entry 1'),
      );
      expect(result.length, 1);
      expect(result.first.id, '1');
    });

    test('filters by start date', () async {
      await seedEntries();
      final result = dataSource.searchEntries(JournalFilter(startDate: date2));
      expect(result.length, 2); // date2 and date3
      expect(result.map((e) => e.id), containsAll(['2', '3']));
    });

    test('filters by end date', () async {
      await seedEntries();
      final result = dataSource.searchEntries(JournalFilter(endDate: date2));
      expect(result.length, 2); // date1 and date2
      expect(result.map((e) => e.id), containsAll(['1', '2']));
    });

    test('filters by date range', () async {
      await seedEntries();
      final result = dataSource.searchEntries(
        JournalFilter(startDate: date2, endDate: date2),
      );
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('filters by category', () async {
      await seedEntries();
      final result = dataSource.searchEntries(
        const JournalFilter(categoryIds: ['cat1']),
      );
      expect(result.length, 2); // entry1 and entry3
      expect(result.map((e) => e.id), containsAll(['1', '3']));
    });

    test('filters by tags', () async {
      await seedEntries();
      final result = dataSource.searchEntries(
        const JournalFilter(tags: ['tag1']),
      );
      expect(result.length, 2); // entry1 and entry3
      expect(result.map((e) => e.id), containsAll(['1', '3']));
    });

    test('filters by combined criteria', () async {
      await seedEntries();
      final result = dataSource.searchEntries(
        JournalFilter(
          startDate: date1,
          endDate: date3,
          categoryIds: ['cat1'],
          tags: ['tag3'],
        ),
      );
      expect(result.length, 1);
      expect(result.first.id, '3');
    });
  });
}
