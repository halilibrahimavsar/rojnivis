import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/journal_entry_model.dart';

abstract class JournalLocalDataSource {
  Future<List<JournalEntryModel>> getEntries();
  Future<void> addEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String id);
  Future<void> updateEntry(JournalEntryModel entry);
  Future<List<JournalEntryModel>> searchEntries(String query);
}

@LazySingleton(as: JournalLocalDataSource)
class JournalLocalDataSourceImpl implements JournalLocalDataSource {
  static const String boxName = 'journalBox';

  Future<Box<JournalEntryModel>> _openBox() async {
    if (!Hive.isBoxOpen(boxName)) {
      return await Hive.openBox<JournalEntryModel>(boxName);
    }
    return Hive.box<JournalEntryModel>(boxName);
  }

  @override
  Future<List<JournalEntryModel>> getEntries() async {
    final box = await _openBox();
    return box.values.toList()..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addEntry(JournalEntryModel entry) async {
    final box = await _openBox();
    await box.put(entry.id, entry);
  }

  @override
  Future<void> deleteEntry(String id) async {
    final box = await _openBox();
    await box.delete(id);
  }

  @override
  Future<void> updateEntry(JournalEntryModel entry) async {
    final box = await _openBox();
    await box.put(entry.id, entry);
  }

  @override
  Future<List<JournalEntryModel>> searchEntries(String query) async {
    final box = await _openBox();
    final lowerQuery = query.toLowerCase();
    return box.values.where((entry) {
      return entry.title.toLowerCase().contains(lowerQuery) ||
             entry.content.toLowerCase().contains(lowerQuery) ||
             entry.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }
}
