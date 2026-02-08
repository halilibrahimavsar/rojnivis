import 'package:injectable/injectable.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

@lazySingleton
class GetCategories {
  final CategoryRepository _repository;

  GetCategories(this._repository);

  Future<List<Category>> call() async {
    return await _repository.getCategories();
  }
}
