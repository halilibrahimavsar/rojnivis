import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:rojnivis/features/categories/data/models/category_model.dart';
import 'package:rojnivis/features/categories/domain/usecases/add_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/delete_category.dart';
import 'package:rojnivis/features/categories/domain/usecases/get_categories.dart';
import 'package:rojnivis/features/categories/presentation/bloc/category_bloc.dart';

class MockGetCategories extends Mock implements GetCategories {}

class MockAddCategory extends Mock implements AddCategory {}

class MockDeleteCategory extends Mock implements DeleteCategory {}

void main() {
  late MockGetCategories mockGetCategories;
  late MockAddCategory mockAddCategory;
  late MockDeleteCategory mockDeleteCategory;

  const testCategory = CategoryModel(
    id: 'test-1',
    name: 'Test Category',
    color: 0xFFFF0000,
    iconPath: '',
  );

  const testCategories = [testCategory];

  setUp(() {
    mockGetCategories = MockGetCategories();
    mockAddCategory = MockAddCategory();
    mockDeleteCategory = MockDeleteCategory();
  });

  setUpAll(() {
    registerFallbackValue(testCategory);
  });

  CategoryBloc buildBloc() =>
      CategoryBloc(mockGetCategories, mockAddCategory, mockDeleteCategory);

  group('CategoryBloc', () {
    test('initial state is CategoryInitial', () {
      expect(buildBloc().state, const CategoryInitial());
    });

    group('LoadCategories', () {
      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoryLoading, CategoryLoaded] when loading succeeds',
        setUp: () {
          when(() => mockGetCategories()).thenAnswer((_) async => testCategories);
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadCategories()),
        expect: () => [
          const CategoryLoading(),
          const CategoryLoaded(categories: testCategories),
        ],
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits [CategoryLoading, CategoryError] when loading fails',
        setUp: () {
          when(() => mockGetCategories()).thenThrow(Exception('Load failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc.add(const LoadCategories()),
        expect: () => [
          const CategoryLoading(),
          isA<CategoryError>(),
        ],
      );
    });

    group('UpsertCategoryRequested', () {
      blocTest<CategoryBloc, CategoryState>(
        'calls addCategory and reloads categories on success',
        setUp: () {
          when(() => mockAddCategory(any())).thenAnswer((_) async {});
          when(() => mockGetCategories()).thenAnswer((_) async => testCategories);
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const UpsertCategoryRequested(category: testCategory)),
        verify: (_) {
          verify(() => mockAddCategory(testCategory)).called(1);
        },
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits CategoryError when upsert fails',
        setUp: () {
          when(() => mockAddCategory(any()))
              .thenThrow(Exception('Upsert failed'));
        },
        build: buildBloc,
        act: (bloc) =>
            bloc.add(const UpsertCategoryRequested(category: testCategory)),
        expect: () => [isA<CategoryError>()],
      );
    });

    group('DeleteCategoryRequested', () {
      blocTest<CategoryBloc, CategoryState>(
        'calls deleteCategory and reloads categories on success',
        setUp: () {
          when(() => mockDeleteCategory(any())).thenAnswer((_) async {});
          when(() => mockGetCategories()).thenAnswer((_) async => testCategories);
        },
        build: buildBloc,
        act: (bloc) => bloc
            .add(const DeleteCategoryRequested(categoryId: 'test-1')),
        verify: (_) {
          verify(() => mockDeleteCategory('test-1')).called(1);
        },
      );

      blocTest<CategoryBloc, CategoryState>(
        'emits CategoryError when delete fails',
        setUp: () {
          when(() => mockDeleteCategory(any()))
              .thenThrow(Exception('Delete failed'));
        },
        build: buildBloc,
        act: (bloc) => bloc
            .add(const DeleteCategoryRequested(categoryId: 'test-1')),
        expect: () => [isA<CategoryError>()],
      );
    });
  });
}
