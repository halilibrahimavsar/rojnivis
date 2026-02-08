import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  List<CategoryModel> getCategories();
  Future<void> upsertCategory(CategoryModel category);
  Future<void> deleteCategory(String categoryId);
}

@LazySingleton(as: CategoryLocalDataSource)
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  Box<CategoryModel> get _box => Hive.box<CategoryModel>(CategoryModel.boxName);

  @override
  List<CategoryModel> getCategories() {
    final categories = _box.values.toList(growable: false);
    categories.sort((a, b) => a.name.compareTo(b.name));
    return categories;
  }

  @override
  Future<void> upsertCategory(CategoryModel category) async {
    await _box.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    await _box.delete(categoryId);
  }
}
