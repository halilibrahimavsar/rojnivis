import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/entry_sticker.dart';
import '../repositories/entry_decoration_repository.dart';

@lazySingleton
class SaveStickers {
  final EntryDecorationRepository _repository;

  SaveStickers(this._repository);

  Future<(Failure?, void)> call(String entryId, List<EntrySticker> stickers) =>
      _repository.saveStickers(entryId, stickers);
}
