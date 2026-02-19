import '../models/entry_sticker.dart';

abstract class EntryDecorationRepository {
  Future<List<EntrySticker>> getStickers(String entryId);

  Future<void> saveStickers(String entryId, List<EntrySticker> stickers);

  Future<void> clearStickers(String entryId);
}
