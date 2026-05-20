import 'package:injectable/injectable.dart';

import '../../../../core/errors/failures.dart';
import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class GetEntries {
  final JournalRepository _repository;

  GetEntries(this._repository);

  Future<(Failure?, List<JournalEntry>?)> call() => _repository.getEntries();
}
