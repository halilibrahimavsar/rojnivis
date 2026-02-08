import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/category_model.dart';

abstract class CategoryLocalDataSource {
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> deleteCategory(String id);
  Future<void> updateCategory(CategoryModel category);
}

@LazySingleton(as: CategoryLocalDataSource)
class CategoryLocalDataSourceImpl implements CategoryLocalDataSource {
  static const String boxName = 'categoriesBox';

  Future<Box<CategoryModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<CategoryModel>(boxName);
    }
    return Hive.box<CategoryModel>(boxName);
  }

  @override
  Future<List<CategoryModel>> getCategories() async {
    final box = await _openBox();
    return box.values.toList();
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    final box = await _openBox();
    await box.put(category.id, category);
  }
}
