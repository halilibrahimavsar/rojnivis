import 'package:injectable/injectable.dart';

import '../repositories/journal_repository.dart';

@injectable
class DeleteEntry {
  final JournalRepository _repository;

  DeleteEntry(this._repository);

  Future<void> call(String entryId) => _repository.deleteEntry(entryId);
}
