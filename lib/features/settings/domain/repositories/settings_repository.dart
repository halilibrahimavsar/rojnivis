import '../../../../core/errors/failures.dart';
import '../entities/user_settings.dart';

abstract class SettingsRepository {
  Future<(Failure?, UserSettings?)> getSettings();
  Future<(Failure?, void)> updateSetting(UserSettings settings);
}
