import 'package:hive/hive.dart';

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

  const CategoryModel({
    required this.id,
    required this.name,
    required this.color,
    required this.iconPath,
  });

  CategoryModel copyWith({
    String? id,
    String? name,
    int? color,
    String? iconPath,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      iconPath: iconPath ?? this.iconPath,
    );
  }
}
