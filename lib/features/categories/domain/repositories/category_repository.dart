import '../../data/models/category_model.dart';

abstract class CategoryRepository {
  Future<List<CategoryModel>> getCategories();
  Future<void> upsertCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);
}
