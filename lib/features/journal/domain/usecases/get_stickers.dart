import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/entry_sticker.dart';
import '../repositories/entry_decoration_repository.dart';

@lazySingleton
class GetStickers {
  final EntryDecorationRepository _repository;

  GetStickers(this._repository);

  Future<(Failure?, List<EntrySticker>?)> call(String entryId) =>
      _repository.getStickers(entryId);
}
