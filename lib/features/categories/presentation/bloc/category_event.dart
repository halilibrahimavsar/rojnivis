part of 'category_bloc.dart';

sealed class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object?> get props => [];
}

class LoadCategories extends CategoryEvent {
  const LoadCategories();
}

class UpsertCategoryRequested extends CategoryEvent {
  final CategoryModel category;

  const UpsertCategoryRequested({required this.category});

  @override
  List<Object?> get props => [category];
}

class DeleteCategoryRequested extends CategoryEvent {
  final String categoryId;

  const DeleteCategoryRequested({required this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}
