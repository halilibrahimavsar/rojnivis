import 'package:injectable/injectable.dart';

import '../../data/models/category_model.dart';
import '../repositories/category_repository.dart';

@lazySingleton
class AddCategory {
  final CategoryRepository _repository;

  AddCategory(this._repository);

  Future<void> call(CategoryModel category) =>
      _repository.upsertCategory(category);
}
