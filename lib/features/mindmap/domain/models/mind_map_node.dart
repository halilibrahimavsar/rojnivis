import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'mind_map_node.g.dart';

@HiveType(typeId: 2)
class MindMapNode extends Equatable {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String label;

  @HiveField(2)
  final List<MindMapNode> children;

  @HiveField(3)
  final double x;

  @HiveField(4)
  final double y;

  @HiveField(5)
  final int colorValue;

  @HiveField(6)
  final String? layoutType; // 'horizontal' or 'vertical'

  @HiveField(7)
  final String? shape; // 'rectangle', 'circle', 'cloud', 'star'

  @HiveField(8)
  final bool? useGradient;

  Color get color => Color(colorValue);
  
  // Non-nullable getters for internal app use
  String get effectiveLayoutType => layoutType ?? 'horizontal';
  String get effectiveShape => shape ?? 'rectangle';
  bool get effectiveUseGradient => useGradient ?? false;

  const MindMapNode({
    required this.id,
    required this.label,
    this.children = const [],
    this.x = 0,
    this.y = 0,
    this.colorValue = 0xFF2196F3, // Default blue
    this.layoutType = 'horizontal',
    this.shape = 'rectangle',
    this.useGradient = false,
  });

  factory MindMapNode.create({
    required String label,
    String? parentId,
    List<MindMapNode> children = const [],
    double x = 100,
    double y = 100,
    int colorValue = 0xFF2196F3,
    String layoutType = 'horizontal',
    String shape = 'rectangle',
    bool useGradient = false,
  }) {
    return MindMapNode(
      id: const Uuid().v4(),
      label: label,
      children: children,
      x: x,
      y: y,
      colorValue: colorValue,
      layoutType: layoutType,
      shape: shape,
      useGradient: useGradient,
    );
  }

  MindMapNode copyWith({
    String? id,
    String? label,
    List<MindMapNode>? children,
    double? x,
    double? y,
    int? colorValue,
    String? layoutType,
    String? shape,
    bool? useGradient,
  }) {
    return MindMapNode(
      id: id ?? this.id,
      label: label ?? this.label,
      children: children ?? this.children,
      x: x ?? this.x,
      y: y ?? this.y,
      colorValue: colorValue ?? this.colorValue,
      layoutType: layoutType ?? this.layoutType,
      shape: shape ?? this.shape,
      useGradient: useGradient ?? this.useGradient,
    );
  }

  // Helper to add a child to a specific parent node ID in the tree
  MindMapNode addChild(String parentId, MindMapNode child) {
    if (id == parentId) {
      return copyWith(children: [...children, child]);
    }

    final newChildren =
        children.map((c) => c.addChild(parentId, child)).toList();
    return copyWith(children: newChildren);
  }

  // Helper to remove a node by ID
  MindMapNode removeChild(String targetId) {
    // Determine if any direct child matches the target
    final newChildren = <MindMapNode>[];

    for (final child in children) {
      if (child.id == targetId) {
        continue; // Skip this child (remove it)
      } else {
        // Recursively try to remove from grandchildren
        newChildren.add(child.removeChild(targetId));
      }
    }

    return copyWith(children: newChildren);
  }

  // Update a specific node
  MindMapNode updateNode(
    String targetId,
    MindMapNode Function(MindMapNode) updateFn,
  ) {
    if (id == targetId) {
      return updateFn(this);
    }

    final newChildren =
        children.map((c) => c.updateNode(targetId, updateFn)).toList();
    return copyWith(children: newChildren);
  }

  @override
  List<Object?> get props => [id, label, children, x, y, colorValue];
}
