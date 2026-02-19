import '../../domain/models/entry_sticker.dart';
import '../../domain/repositories/entry_decoration_repository.dart';
import '../datasources/entry_decoration_local_datasource.dart';

class EntryDecorationRepositoryImpl implements EntryDecorationRepository {
  EntryDecorationRepositoryImpl({
    EntryDecorationLocalDataSource? localDataSource,
  }) : _localDataSource = localDataSource ?? EntryDecorationLocalDataSourceImpl();

  final EntryDecorationLocalDataSource _localDataSource;

  @override
  Future<void> clearStickers(String entryId) {
    return _localDataSource.clearStickers(entryId);
  }

  @override
  Future<List<EntrySticker>> getStickers(String entryId) {
    return _localDataSource.getStickers(entryId);
  }

  @override
  Future<void> saveStickers(String entryId, List<EntrySticker> stickers) {
    return _localDataSource.saveStickers(entryId, stickers);
  }
}
