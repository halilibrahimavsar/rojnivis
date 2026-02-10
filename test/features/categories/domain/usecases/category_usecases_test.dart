import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rojnivis/features/categories/data/models/category_model.dart';
import 'package:rojnivis/features/categories/domain/repositories/category_repository.dart';
import 'package:rojnivis/features/categories/domain/usecases/add_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/delete_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/get_categories.dart';

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockCategoryRepository mockRepository;

  const testCategory = CategoryModel(
    id: 'test-1',
    name: 'Test',
    color: 0xFFFF0000,
    iconPath: '',
  );

  setUp(() {
    mockRepository = MockCategoryRepository();
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
      when(() => mockRepository.getCategories())
          .thenAnswer((_) async => [testCategory]);

      final result = await getCategories();

      expect(result, [testCategory]);
      verify(() => mockRepository.getCategories()).called(1);
    });
  });

  group('AddCategory', () {
    late AddCategory addCategory;

    setUp(() {
      addCategory = AddCategory(mockRepository);
    });

    test('delegates to repository.upsertCategory()', () async {
      when(() => mockRepository.upsertCategory(any()))
          .thenAnswer((_) async {});

      await addCategory(testCategory);

      verify(() => mockRepository.upsertCategory(testCategory)).called(1);
    });
  });

  group('DeleteCategory', () {
    late DeleteCategory deleteCategory;

    setUp(() {
      deleteCategory = DeleteCategory(mockRepository);
    });

    test('delegates to repository.deleteCategory()', () async {
      when(() => mockRepository.deleteCategory(any()))
          .thenAnswer((_) async {});

      await deleteCategory('test-1');

      verify(() => mockRepository.deleteCategory('test-1')).called(1);
    });
  });
}
