import '../../../../core/errors/failures.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';
import 'package:injectable/injectable.dart';

@lazySingleton
class GetCategories {
  final CategoryRepository _repository;

  GetCategories(this._repository);

  Future<(Failure?, List<Category>?)> call() => _repository.getCategories();
}
