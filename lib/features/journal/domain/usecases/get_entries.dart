import 'package:injectable/injectable.dart';

import '../../data/models/journal_entry_model.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class GetEntries {
  final JournalRepository _repository;

  GetEntries(this._repository);

  Future<List<JournalEntryModel>> call() => _repository.getEntries();
}
