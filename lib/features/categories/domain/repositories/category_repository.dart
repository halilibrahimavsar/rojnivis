import '../../../../core/errors/failures.dart';
import '../entities/category.dart';

abstract class CategoryRepository {
  Future<(Failure?, List<Category>?)> getCategories();
  Future<(Failure?, void)> upsertCategory(Category category);
  Future<(Failure?, void)> deleteCategory(String categoryId);
}
