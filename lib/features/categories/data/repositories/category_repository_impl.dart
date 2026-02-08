import 'package:injectable/injectable.dart';

import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _local;

  CategoryRepositoryImpl(this._local);

  @override
  Future<List<CategoryModel>> getCategories() async => _local.getCategories();

  @override
  Future<void> upsertCategory(CategoryModel category) =>
      _local.upsertCategory(category);

  @override
  Future<void> deleteCategory(String categoryId) =>
      _local.deleteCategory(categoryId);
}
