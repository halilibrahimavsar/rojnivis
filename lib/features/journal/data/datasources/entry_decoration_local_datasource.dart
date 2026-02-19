import 'dart:convert';

import 'package:hive/hive.dart';

import '../../../../core/constants/app_constants.dart';
import '../../domain/models/entry_sticker.dart';

abstract class EntryDecorationLocalDataSource {
  Future<List<EntrySticker>> getStickers(String entryId);

  Future<void> saveStickers(String entryId, List<EntrySticker> stickers);

  Future<void> clearStickers(String entryId);
}

class EntryDecorationLocalDataSourceImpl
    implements EntryDecorationLocalDataSource {
  Box<String> get _box => Hive.box<String>(StorageKeys.entryDecorationsBox);

  @override
  Future<List<EntrySticker>> getStickers(String entryId) async {
    final raw = _box.get(entryId);
    if (raw == null || raw.isEmpty) return const [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final stickers = <EntrySticker>[];
      for (final item in decoded) {
        if (item is Map<String, dynamic>) {
          stickers.add(EntrySticker.fromJson(item));
        } else if (item is Map) {
          stickers.add(
            EntrySticker.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
      stickers.sort((a, b) => a.zIndex.compareTo(b.zIndex));
      return stickers;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveStickers(String entryId, List<EntrySticker> stickers) async {
    final payload = jsonEncode(stickers.map((s) => s.toJson()).toList(growable: false));
    await _box.put(entryId, payload);
  }

  @override
  Future<void> clearStickers(String entryId) async {
    await _box.delete(entryId);
  }
}
