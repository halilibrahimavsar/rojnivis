import 'package:injectable/injectable.dart';
import '../repositories/journal_repository.dart';

@injectable
class DeleteEntry {
  final JournalRepository repository;

  DeleteEntry(this.repository);

  Future<void> call(String id) async {
    return await repository.deleteEntry(id);
  }
}
