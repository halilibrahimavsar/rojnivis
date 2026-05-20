import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../repositories/journal_repository.dart';

@injectable
class DeleteEntry {
  final JournalRepository _repository;

  DeleteEntry(this._repository);

  Future<(Failure?, void)> call(String entryId) =>
      _repository.deleteEntry(entryId);
}
