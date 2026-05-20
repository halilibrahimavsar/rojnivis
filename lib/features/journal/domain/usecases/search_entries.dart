import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry.dart';
import '../entities/journal_filter.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class SearchEntries {
  final JournalRepository _repository;

  SearchEntries(this._repository);

  Future<(Failure?, List<JournalEntry>?)> call(JournalFilter filter) =>
      _repository.searchEntries(filter);
}
