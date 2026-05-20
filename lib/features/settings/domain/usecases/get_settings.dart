import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/user_settings.dart';
import '../repositories/settings_repository.dart';

@lazySingleton
class GetSettings {
  final SettingsRepository _repository;

  GetSettings(this._repository);

  Future<(Failure?, UserSettings?)> call() => _repository.getSettings();
}
