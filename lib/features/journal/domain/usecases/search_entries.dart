import 'package:injectable/injectable.dart';

import '../../data/models/journal_entry_model.dart';
import '../models/filter_model.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class SearchEntries {
  final JournalRepository _repository;

  SearchEntries(this._repository);

  Future<List<JournalEntryModel>> call(JournalFilter filter) =>
      _repository.searchEntries(filter);
}
