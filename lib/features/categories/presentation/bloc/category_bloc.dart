import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../data/models/category_model.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_categories.dart';

part 'category_event.dart';
part 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories _getCategories;
  final AddCategory _addCategory;
  final DeleteCategory _deleteCategory;

  CategoryBloc(this._getCategories, this._addCategory, this._deleteCategory)
    : super(const CategoryInitial()) {
    on<LoadCategories>(_onLoad);
    on<UpsertCategoryRequested>(_onUpsert);
    on<DeleteCategoryRequested>(_onDelete);
  }

  Future<void> _onLoad(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(const CategoryLoading());
    try {
      final categories = await _getCategories();
      emit(CategoryLoaded(categories: categories));
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onUpsert(
    UpsertCategoryRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _addCategory(event.category);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }

  Future<void> _onDelete(
    DeleteCategoryRequested event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _deleteCategory(event.categoryId);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(message: e.toString()));
    }
  }
}
