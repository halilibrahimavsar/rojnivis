part of 'mind_map_bloc.dart';

sealed class MindMapEvent extends Equatable {
  const MindMapEvent();

  @override
  List<Object?> get props => [];
}

class LoadMindMaps extends MindMapEvent {
  const LoadMindMaps();
}

class SaveMindMap extends MindMapEvent {
  final MindMapNode node;

  const SaveMindMap(this.node);

  @override
  List<Object> get props => [node];
}

class DeleteMindMap extends MindMapEvent {
  final String id;

  const DeleteMindMap(this.id);

  @override
  List<Object> get props => [id];
}

class AddNode extends MindMapEvent {
  final String parentId;
  final MindMapNode node;

  const AddNode({required this.parentId, required this.node});

  @override
  List<Object> get props => [parentId, node];
}

class UpdateNode extends MindMapEvent {
  final String nodeId;
  final String? newLabel;
  final Color? newColor;
  final double? newX;
  final double? newY;

  const UpdateNode({
    required this.nodeId,
    this.newLabel,
    this.newColor,
    this.newX,
    this.newY,
  });

  @override
  List<Object?> get props => [nodeId, newLabel, newColor, newX, newY];
}

class DeleteNode extends MindMapEvent {
  final String mindMapId;
  final String nodeId;

  const DeleteNode({required this.mindMapId, required this.nodeId});

  @override
  List<Object> get props => [mindMapId, nodeId];
}

class SelectMindMap extends MindMapEvent {
  final MindMapNode node;

  const SelectMindMap(this.node);

  @override
  List<Object> get props => [node];
}
