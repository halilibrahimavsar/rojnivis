import 'package:injectable/injectable.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

@lazySingleton
class AddCategory {
  final CategoryRepository _repository;

  AddCategory(this._repository);

  Future<void> call(Category category) async {
    await _repository.addCategory(category);
  }
}
