import '../../../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class AddCategory {
  final CategoryRepository _repository;

  AddCategory(this._repository);

  Future<(Failure?, void)> call(Category category) =>
      _repository.upsertCategory(category);
}
