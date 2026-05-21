import 'package:hive/hive.dart';
import '../../domain/entities/category.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel {
  static const String boxName = 'categories';

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int color;

  @HiveField(3)
  final String iconPath;

  @HiveField(4)
  final String? parentId;

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.iconPath,
    this.parentId,
  });

  /// Creates a model from a domain entity.
  factory CategoryModel.fromEntity(Category entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      color: entity.color,
      iconPath: entity.iconPath,
      parentId: entity.parentId,
    );
  }

  /// Converts this model to a domain entity.
  Category toEntity() {
    return Category(
      id: id,
      name: name,
      color: color,
      iconPath: iconPath,
      parentId: parentId,
    );
  }

  CategoryModel copyWith({
    String? id,
    String? name,
    int? color,
    String? iconPath,
    String? parentId,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
      parentId: parentId ?? this.parentId,
    );
  }
}
