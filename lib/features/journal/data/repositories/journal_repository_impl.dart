import 'package:injectable/injectable.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_local_datasource.dart';
import '../models/journal_entry_model.dart';

@LazySingleton(as: JournalRepository)
class JournalRepositoryImpl implements JournalRepository {
  final JournalLocalDataSource _localDataSource;

  JournalRepositoryImpl(this._localDataSource);

  @override
  Future<List<JournalEntry>> getEntries() async {
    final models = await _localDataSource.getEntries();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> addEntry(JournalEntry entry) async {
    await _localDataSource.addEntry(JournalEntryModel.fromEntity(entry));
  }

  @override
  Future<void> deleteEntry(String id) async {
    await _localDataSource.deleteEntry(id);
  }

  @override
  Future<void> updateEntry(JournalEntry entry) async {
    await _localDataSource.updateEntry(JournalEntryModel.fromEntity(entry));
  }

  @override
  Future<List<JournalEntry>> searchEntries(String query) async {
    final models = await _localDataSource.searchEntries(query);
    return models.map((e) => e.toEntity()).toList();
  }
}
