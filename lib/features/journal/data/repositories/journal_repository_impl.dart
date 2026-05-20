import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/journal_filter.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_datasource.dart';
import '../models/journal_entry_model.dart';

@LazySingleton(as: JournalRepository)
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource _local;

  JournalRepositoryImpl(this._local);

  @override
  Future<(Failure?, List<JournalEntry>?)> getEntries() async {
    try {
      final models = _local.getEntries();
      final entities = models.map((m) => m.toEntity()).toList();
      return (null, entities);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, JournalEntry?)> getEntry(String entryId) async {
    try {
      final model = _local.getEntry(entryId);
      return (null, model?.toEntity());
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> upsertEntry(JournalEntry entry) async {
    try {
      await _local.upsertEntry(JournalEntryModel.fromEntity(entry));
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, void)> deleteEntry(String entryId) async {
    try {
      await _local.deleteEntry(entryId);
      return (null, null);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }

  @override
  Future<(Failure?, List<JournalEntry>?)> searchEntries(
    JournalFilter filter,
  ) async {
    try {
      final models = _local.searchEntries(filter);
      final entities = models.map((m) => m.toEntity()).toList();
      return (null, entities);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }
}
