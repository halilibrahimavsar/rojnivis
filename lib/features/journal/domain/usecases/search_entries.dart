import 'package:injectable/injectable.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class SearchEntries {
  final JournalRepository _repository;

  SearchEntries(this._repository);

  Future<List<JournalEntry>> call(String query) async {
    return await _repository.searchEntries(query);
  }
}
