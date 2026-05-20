import '../../../../core/errors/failures.dart';
import '../entities/journal_entry.dart';
import '../entities/journal_filter.dart';

abstract class JournalRepository {
  Future<(Failure?, List<JournalEntry>?)> getEntries();
  Future<(Failure?, JournalEntry?)> getEntry(String entryId);
  Future<(Failure?, void)> upsertEntry(JournalEntry entry);
  Future<(Failure?, void)> deleteEntry(String entryId);
  Future<(Failure?, List<JournalEntry>?)> searchEntries(JournalFilter filter);
}
