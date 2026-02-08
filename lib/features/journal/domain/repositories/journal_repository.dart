import '../../data/models/journal_entry_model.dart';
import '../models/filter_model.dart';

abstract class JournalRepository {
  Future<List<JournalEntryModel>> getEntries();
  Future<JournalEntryModel?> getEntry(String entryId);
  Future<void> upsertEntry(JournalEntryModel entry);
  Future<void> deleteEntry(String entryId);
  Future<List<JournalEntryModel>> searchEntries(JournalFilter filter);
}
