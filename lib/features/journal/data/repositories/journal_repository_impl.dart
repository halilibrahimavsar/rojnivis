import 'package:injectable/injectable.dart';

import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_datasource.dart';
import '../models/journal_entry_model.dart';
import '../../domain/models/filter_model.dart';

@LazySingleton(as: JournalRepository)
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource _local;

  JournalRepositoryImpl(this._local);

  @override
  Future<List<JournalEntryModel>> getEntries() async => _local.getEntries();

  @override
  Future<JournalEntryModel?> getEntry(String entryId) async =>
      _local.getEntry(entryId);

  @override
  Future<void> upsertEntry(JournalEntryModel entry) =>
      _local.upsertEntry(entry);

  @override
  Future<void> deleteEntry(String entryId) => _local.deleteEntry(entryId);

  @override
  Future<List<JournalEntryModel>> searchEntries(JournalFilter filter) async =>
      _local.searchEntries(filter);
}
