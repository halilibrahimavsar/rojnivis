import 'package:injectable/injectable.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class GetEntries {
  final JournalRepository _repository;

  GetEntries(this._repository);

  Future<List<JournalEntry>> call() async {
    return await _repository.getEntries();
  }
}
