import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/entry_sticker.dart';
import '../../domain/repositories/entry_decoration_repository.dart';
import '../datasources/entry_decoration_local_datasource.dart';

@LazySingleton(as: EntryDecorationRepository)
class EntryDecorationRepositoryImpl implements EntryDecorationRepository {
  final EntryDecorationLocalDataSource _localDataSource;

  EntryDecorationRepositoryImpl(this._localDataSource);

  @override
  Future<(Failure?, void)> clearStickers(String entryId) async {
    try {
      await _localDataSource.clearStickers(entryId);
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, List<EntrySticker>?)> getStickers(String entryId) async {
    try {
      final stickers = await _localDataSource.getStickers(entryId);
      return (null, stickers);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> saveStickers(
    String entryId,
    List<EntrySticker> stickers,
  ) async {
    try {
      await _localDataSource.saveStickers(entryId, stickers);
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }
}
