import '../../../../core/errors/failures.dart';
import 'package:injectable/injectable.dart';

import '../repositories/category_repository.dart';
import '../../../journal/domain/repositories/journal_repository.dart';

@injectable
class DeleteCategory {
  final CategoryRepository _repository;
  final JournalRepository _journalRepository;

  DeleteCategory(this._repository, this._journalRepository);

  Future<(Failure?, void)> call(String categoryId) async {
    // 1. Get all categories to find descendants
    final (catFailure, categories) = await _repository.getCategories();
    if (catFailure != null) return (catFailure, null);

    final Set<String> categoriesToDelete = {categoryId};
    bool addedNew = true;
    while (addedNew) {
      addedNew = false;
      for (final cat in categories!) {
        if (cat.parentId != null &&
            categoriesToDelete.contains(cat.parentId) &&
            !categoriesToDelete.contains(cat.id)) {
          categoriesToDelete.add(cat.id);
          addedNew = true;
        }
      }
    }

    // 2. Delete all categories found
    for (final id in categoriesToDelete) {
      final (delFailure, _) = await _repository.deleteCategory(id);
      if (delFailure != null) return (delFailure, null);
    }

    // 3. Update all journal entries that belong to deleted categories
    final (entryFailure, entries) = await _journalRepository.getEntries();
    if (entryFailure != null) return (entryFailure, null);

    if (entries != null) {
      for (final entry in entries) {
        if (entry.categoryId != null &&
            categoriesToDelete.contains(entry.categoryId)) {
          final updatedEntry = entry.copyWith(clearCategoryId: true);
          final (updFailure, _) = await _journalRepository.upsertEntry(
            updatedEntry,
          );
          if (updFailure != null) return (updFailure, null);
        }
      }
    }

    return (null, null);
  }
}
