import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:rojnivis/core/errors/failures.dart';
import 'package:rojnivis/features/categories/domain/entities/category.dart';
import 'package:rojnivis/features/categories/domain/repositories/category_repository.dart';
import 'package:rojnivis/features/categories/domain/usecases/add_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/delete_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/get_categories.dart';

import 'package:rojnivis/features/journal/domain/entities/journal_entry.dart';
import 'package:rojnivis/features/journal/domain/repositories/journal_repository.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockJournalRepository extends Mock implements JournalRepository {}

void main() {
  late MockCategoryRepository mockRepository;
  late MockJournalRepository mockJournalRepository;

  const testCategory = Category(
    id: 'test-1',
    name: 'Test',
    color: 0xFFFF0000,
    iconPath: '',
  );

  setUp(() {
    mockRepository = MockCategoryRepository();
    mockJournalRepository = MockJournalRepository();
  });

  setUpAll(() {
    registerFallbackValue(testCategory);
  });

  group('GetCategories', () {
    late GetCategories getCategories;

    setUp(() {
      getCategories = GetCategories(mockRepository);
    });

    test('delegates to repository.getCategories()', () async {
      when(
        () => mockRepository.getCategories(),
      ).thenAnswer((_) async => (null, [testCategory]));

      final result = await getCategories();

      expect(result.$2, [testCategory]);
      verify(() => mockRepository.getCategories()).called(1);
    });

    test('returns failure when repository fails', () async {
      const failure = StorageFailure(message: 'Error');
      when(
        () => mockRepository.getCategories(),
      ).thenAnswer((_) async => (failure, null));

      final result = await getCategories();

      expect(result.$1, failure);
      verify(() => mockRepository.getCategories()).called(1);
    });
  });

  group('AddCategory', () {
    late AddCategory addCategory;

    setUp(() {
      addCategory = AddCategory(mockRepository);
    });

    test('delegates to repository.upsertCategory()', () async {
      when(
        () => mockRepository.upsertCategory(any()),
      ).thenAnswer((_) async => (null, null));

      final result = await addCategory(testCategory);

      expect(result.$1, isNull);
      verify(() => mockRepository.upsertCategory(testCategory)).called(1);
    });
  });

  group('DeleteCategory', () {
    late DeleteCategory deleteCategory;

    setUp(() {
      deleteCategory = DeleteCategory(mockRepository, mockJournalRepository);
    });

    test('delegates to repository.deleteCategory()', () async {
      when(
        () => mockRepository.getCategories(),
      ).thenAnswer((_) async => (null, [testCategory]));
      when(
        () => mockJournalRepository.getEntries(),
      ).thenAnswer((_) async => (null, <JournalEntry>[]));
      when(
        () => mockRepository.deleteCategory(any()),
      ).thenAnswer((_) async => (null, null));

      final result = await deleteCategory('test-1');

      expect(result.$1, isNull);
      verify(() => mockRepository.deleteCategory('test-1')).called(1);
    });
    group('Failure cases', () {
      test('DeleteCategory returns failure when repo fails', () async {
        const failure = StorageFailure(message: 'Delete failed');
        when(
          () => mockRepository.getCategories(),
        ).thenAnswer((_) async => (null, [testCategory]));
        when(
          () => mockJournalRepository.getEntries(),
        ).thenAnswer((_) async => (null, <JournalEntry>[]));
        when(
          () => mockRepository.deleteCategory(any()),
        ).thenAnswer((_) async => (failure, null));

        final result = await deleteCategory('test-1');

        expect(result.$1, failure);
      });
    });
  });
}
