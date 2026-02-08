import '../entities/journal_entry.dart';

abstract class JournalRepository {
  Future<List<JournalEntry>> getEntries();
  Future<void> addEntry(JournalEntry entry);
  Future<void> deleteEntry(String id);
  Future<void> updateEntry(JournalEntry entry);
  Future<List<JournalEntry>> searchEntries(String query);
}
