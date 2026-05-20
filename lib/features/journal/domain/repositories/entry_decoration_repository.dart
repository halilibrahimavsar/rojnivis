import '../../../../core/errors/failures.dart';
import '../entities/entry_sticker.dart';

abstract class EntryDecorationRepository {
  Future<(Failure?, List<EntrySticker>?)> getStickers(String entryId);

  Future<(Failure?, void)> saveStickers(
    String entryId,
    List<EntrySticker> stickers,
  );

  Future<(Failure?, void)> clearStickers(String entryId);
}
