import 'package:injectable/injectable.dart';

import '../../data/models/category_model.dart';
import '../repositories/category_repository.dart';

@lazySingleton
class GetCategories {
  final CategoryRepository _repository;

  GetCategories(this._repository);

  Future<List<CategoryModel>> call() => _repository.getCategories();
}
