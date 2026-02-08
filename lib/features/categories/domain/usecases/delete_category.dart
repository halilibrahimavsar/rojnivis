import 'package:injectable/injectable.dart';

import '../repositories/category_repository.dart';

@injectable
class DeleteCategory {
  final CategoryRepository _repository;

  DeleteCategory(this._repository);

  Future<void> call(String categoryId) =>
      _repository.deleteCategory(categoryId);
}
