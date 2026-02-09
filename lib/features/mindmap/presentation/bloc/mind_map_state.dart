part of 'mind_map_bloc.dart';

sealed class MindMapState extends Equatable {
  const MindMapState();

  @override
  List<Object> get props => [];
}

class MindMapInitial extends MindMapState {
  const MindMapInitial();
}

class MindMapLoading extends MindMapState {
  const MindMapLoading();
}

class MindMapLoaded extends MindMapState {
  final List<MindMapNode> mindMaps;
  final MindMapNode? selectedMindMap;

  const MindMapLoaded({required this.mindMaps, this.selectedMindMap});

  MindMapLoaded copyWith({
    List<MindMapNode>? mindMaps,
    MindMapNode? selectedMindMap,
  }) {
    return MindMapLoaded(
      mindMaps: mindMaps ?? this.mindMaps,
      selectedMindMap: selectedMindMap ?? this.selectedMindMap,
    );
  }

  @override
  List<Object> get props => [mindMaps, selectedMindMap ?? ''];
}

class MindMapError extends MindMapState {
  final String message;

  const MindMapError(this.message);

  @override
  List<Object> get props => [message];
}
