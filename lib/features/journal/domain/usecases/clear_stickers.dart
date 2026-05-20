import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/entry_decoration_repository.dart';

@lazySingleton
class ClearStickers {
  final EntryDecorationRepository _repository;

  ClearStickers(this._repository);

  Future<(Failure?, void)> call(String entryId) =>
      _repository.clearStickers(entryId);
}
