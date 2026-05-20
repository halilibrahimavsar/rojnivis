import '../../../../core/errors/failures.dart';
import 'package:injectable/injectable.dart';

import '../repositories/category_repository.dart';

@injectable
class DeleteCategory {
  final CategoryRepository _repository;

  DeleteCategory(this._repository);

  Future<(Failure?, void)> call(String categoryId) =>
      _repository.deleteCategory(categoryId);
}
