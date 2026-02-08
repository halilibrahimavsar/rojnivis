import 'package:injectable/injectable.dart';

import '../../data/models/journal_entry_model.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class AddEntry {
  final JournalRepository _repository;

  AddEntry(this._repository);

  Future<void> call(JournalEntryModel entry) => _repository.upsertEntry(entry);
}
