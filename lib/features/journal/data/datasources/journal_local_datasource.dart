import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/constants/app_constants.dart';
import '../models/journal_entry_model.dart';
import '../../domain/models/filter_model.dart';

abstract class JournalLocalDataSource {
  List<JournalEntryModel> getEntries();
  JournalEntryModel? getEntry(String entryId);
  Future<void> upsertEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
  List<JournalEntryModel> searchEntries(JournalFilter filter);
}

@LazySingleton(as: JournalLocalDataSource)
class JournalLocalDataSourceImpl implements JournalLocalDataSource {
  Box<JournalEntryModel> get _box =>
      Hive.box<JournalEntryModel>(JournalEntryModel.boxName);

  @override
  List<JournalEntryModel> getEntries() {
    final entries = _box.values.toList(growable: false);
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  @override
  JournalEntryModel? getEntry(String entryId) => _box.get(entryId);

  @override
  Future<void> upsertEntry(JournalEntryModel entry) async {
    await _box.put(entry.id, entry);
  }

  @override
  Future<void> deleteEntry(String entryId) async {
    await _box.delete(entryId);
    await Hive.box<String>(StorageKeys.entryDecorationsBox).delete(entryId);
  }

  @override
  List<JournalEntryModel> searchEntries(JournalFilter filter) {
    var entries = getEntries();

    if (filter.isEmpty) return entries;

    // Filter by query
    if (filter.query.isNotEmpty) {
      final q = filter.query.trim().toLowerCase();
      entries = entries
          .where(
            (e) =>
                e.title.toLowerCase().contains(q) ||
                e.content.toLowerCase().contains(q),
          )
          .toList(growable: false);
    }

    // Filter by date range
    if (filter.startDate != null) {
      entries = entries
          .where(
            (e) =>
                !e.date.isBefore(filter.startDate!) ||
                _isSameDay(e.date, filter.startDate!),
          )
          .toList(growable: false);
    }

    if (filter.endDate != null) {
      entries = entries
          .where(
            (e) =>
                !e.date.isAfter(filter.endDate!) ||
                _isSameDay(e.date, filter.endDate!),
          )
          .toList(growable: false);
    }

    // Filter by categories
    if (filter.categoryIds != null && filter.categoryIds!.isNotEmpty) {
      entries = entries
          .where((e) => filter.categoryIds!.contains(e.categoryId))
          .toList(growable: false);
    }

    // Filter by tags
    if (filter.tags != null && filter.tags!.isNotEmpty) {
      entries = entries
          .where((e) => e.tags.any((tag) => filter.tags!.contains(tag)))
          .toList(growable: false);
    }

    return entries;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
