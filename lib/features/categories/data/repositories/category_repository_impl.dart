import '../../../../core/errors/failures.dart';
import '../../domain/entities/category.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/category_local_datasource.dart';
import '../models/category_model.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  final CategoryLocalDataSource _local;

  CategoryRepositoryImpl(this._local);

  @override
  Future<(Failure?, List<Category>?)> getCategories() async {
    try {
      final models = _local.getCategories();
      return (null, models.map((m) => m.toEntity()).toList());
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> upsertCategory(Category category) async {
    try {
      await _local.upsertCategory(CategoryModel.fromEntity(category));
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> deleteCategory(String categoryId) async {
    try {
      await _local.deleteCategory(categoryId);
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }
}
