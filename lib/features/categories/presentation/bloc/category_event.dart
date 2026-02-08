part of 'category_bloc.dart';

abstract class CategoryEvent extends Equatable {
  const CategoryEvent();

  @override
  List<Object> get props => [];
}

class LoadCategories extends CategoryEvent {}

class AddCategoryEvent extends CategoryEvent {
  final Category category;

  const AddCategoryEvent(this.category);

  @override
  List<Object> get props => [category];
}
