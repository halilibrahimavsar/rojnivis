import 'package:injectable/injectable.dart';

import '../../domain/models/mind_map_node.dart';
import '../../domain/repositories/mind_map_repository.dart';
import '../datasources/mind_map_local_datasource.dart';

@LazySingleton(as: MindMapRepository)
class MindMapRepositoryImpl implements MindMapRepository {
  final MindMapLocalDataSource _localDataSource;

  MindMapRepositoryImpl(this._localDataSource);

  @override
  Future<List<MindMapNode>> getMindMaps() async {
    return _localDataSource.getMindMaps();
  }

  @override
  Future<MindMapNode?> getMindMap(String id) async {
    return _localDataSource.getMindMap(id);
  }

  @override
  Future<void> saveMindMap(MindMapNode node) async {
    return _localDataSource.saveMindMap(node);
  }

  @override
  Future<void> deleteMindMap(String id) async {
    return _localDataSource.deleteMindMap(id);
  }
}
