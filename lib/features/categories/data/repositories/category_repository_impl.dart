import 'package:injectable/injectable.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _localDataSource;

  CategoryRepositoryImpl(this._localDataSource);

  @override
  Future<List<Category>> getCategories() async {
    final models = await _localDataSource.getCategories();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addCategory(Category category) async {
    await _localDataSource.addCategory(CategoryModel.fromEntity(category));
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _localDataSource.deleteCategory(id);
  }

  @override
  Future<void> updateCategory(Category category) async {
    await _localDataSource.updateCategory(CategoryModel.fromEntity(category));
  }
}
