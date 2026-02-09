import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../domain/models/mind_map_node.dart';

abstract class MindMapLocalDataSource {
  List<MindMapNode> getMindMaps();
  MindMapNode? getMindMap(String id);
  Future<void> saveMindMap(MindMapNode node);
  Future<void> deleteMindMap(String id);
}

@LazySingleton(as: MindMapLocalDataSource)
class MindMapLocalDataSourceImpl implements MindMapLocalDataSource {
  static const String boxName = 'mind_maps';

  Box<MindMapNode> get _box => Hive.box<MindMapNode>(boxName);

  @override
  List<MindMapNode> getMindMaps() {
    return _box.values.toList();
  }

  @override
  MindMapNode? getMindMap(String id) {
    return _box.get(id);
  }

  @override
  Future<void> saveMindMap(MindMapNode node) async {
    await _box.put(node.id, node);
  }

  @override
  Future<void> deleteMindMap(String id) async {
    await _box.delete(id);
  }
}
