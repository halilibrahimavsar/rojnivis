import 'package:injectable/injectable.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class AddEntry {
  final JournalRepository _repository;

  AddEntry(this._repository);

  Future<void> call(JournalEntry entry) async {
    await _repository.addEntry(entry);
  }
}
