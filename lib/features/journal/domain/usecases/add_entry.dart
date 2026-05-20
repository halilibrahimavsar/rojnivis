import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class AddEntry {
  final JournalRepository _repository;

  AddEntry(this._repository);

  Future<(Failure?, void)> call(JournalEntry entry) =>
      _repository.upsertEntry(entry);
}
