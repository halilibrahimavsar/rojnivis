import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

@lazySingleton
class UpdateSettings {
  final SettingsRepository _repository;

  UpdateSettings(this._repository);

  Future<(Failure?, void)> call(UserSettings settings) =>
      _repository.updateSetting(settings);
}
