import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/add_category.dart';
import '../../domain/usecases/get_categories.dart';

part 'category_event.dart';
part 'category_state.dart';

@injectable
class CategoryBloc extends Bloc<CategoryEvent, CategoryState> {
  final GetCategories _getCategories;
  final AddCategory _addCategory;

  CategoryBloc(this._getCategories, this._addCategory) : super(CategoryInitial()) {
    on<LoadCategories>(_onLoadCategories);
    on<AddCategoryEvent>(_onAddCategory);
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CategoryState> emit,
  ) async {
    emit(CategoryLoading());
    try {
      final categories = await _getCategories();
      emit(CategoryLoaded(categories));
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }

  Future<void> _onAddCategory(
    AddCategoryEvent event,
    Emitter<CategoryState> emit,
  ) async {
    try {
      await _addCategory(event.category);
      add(LoadCategories());
    } catch (e) {
      emit(CategoryError(e.toString()));
    }
  }
}
