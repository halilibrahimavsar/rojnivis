import '../models/mind_map_node.dart';

abstract class MindMapRepository {
  Future<List<MindMapNode>> getMindMaps();
  Future<MindMapNode?> getMindMap(String id);
  Future<void> saveMindMap(MindMapNode node);
  Future<void> deleteMindMap(String id);
}
