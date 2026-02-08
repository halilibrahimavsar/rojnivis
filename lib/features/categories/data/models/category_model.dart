import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int color;

  @HiveField(3)
  final String iconPath;

  CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.iconPath,
  });

  factory CategoryModel.fromEntity(Category category) {
    return CategoryModel(
      id: category.id,
      name: category.name,
      color: category.color,
      iconPath: category.iconPath,
    );
  }

  Category toEntity() {
    return Category(
      id: id,
      name: name,
      color: color,
      iconPath: iconPath,
    );
  }
}
