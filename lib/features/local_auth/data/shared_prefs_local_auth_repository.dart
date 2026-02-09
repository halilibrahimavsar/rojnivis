import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:injectable/injectable.dart';
import 'local_auth_repository.dart';
import '../presentation/constants/local_auth_constants.dart';

@LazySingleton(as: LocalAuthRepository)
class SharedPrefsLocalAuthRepository implements LocalAuthRepository {
  final SharedPreferences _prefs;
  final LocalAuthentication _auth;
  final _settingsChangeController = StreamController<void>.broadcast();

  SharedPrefsLocalAuthRepository({
    required SharedPreferences prefs,
    required LocalAuthentication auth,
  })  : _prefs = prefs,
        _auth = auth;

  @override
  Stream<void> get settingsChanges => _settingsChangeController.stream;

  @override
  Future<bool> isBiometricAvailable() async {
    final canCheck = await _auth.canCheckBiometrics;
    final supported = await _auth.isDeviceSupported();
    return canCheck && supported;
  }

  @override
  Future<bool> isBiometricEnabled() async {
    return _prefs.getBool(LocalAuthConstants.biometricEnabledKey) ?? false;
  }

  @override
  Future<void> setBiometricEnabled(bool enabled) async {
    await _prefs.setBool(LocalAuthConstants.biometricEnabledKey, enabled);
    _settingsChangeController.add(null);
  }

  @override
  Future<bool> isPinSet() async {
    final hash = _prefs.getString(LocalAuthConstants.pinHashKey);
    final salt = _prefs.getString(LocalAuthConstants.pinSaltKey);
    return hash != null && salt != null;
  }

  @override
  Future<void> savePin(String pin) async {
    final salt = _generateSalt();
    final hash = _hashPin(pin, salt);
    await _prefs.setString(LocalAuthConstants.pinSaltKey, salt);
    await _prefs.setString(LocalAuthConstants.pinHashKey, hash);
    _settingsChangeController.add(null);
  }

  @override
  Future<bool> verifyPin(String pin) async {
    final salt = _prefs.getString(LocalAuthConstants.pinSaltKey);
    final hash = _prefs.getString(LocalAuthConstants.pinHashKey);
    if (salt == null || hash == null) return false;
    return _hashPin(pin, salt) == hash;
  }

  @override
  Future<void> deletePin() async {
    await _prefs.remove(LocalAuthConstants.pinSaltKey);
    await _prefs.remove(LocalAuthConstants.pinHashKey);
    _settingsChangeController.add(null);
  }

  @override
  Future<bool> authenticateWithBiometrics({String? reason}) async {
    final available = await isBiometricAvailable();
    if (!available) return false;
    return _auth.authenticate(
      localizedReason: reason ?? LocalAuthConstants.defaultBiometricReason,
      options: const AuthenticationOptions(
        biometricOnly: true,
        stickyAuth: true,
        useErrorDialogs: true,
      ),
    );
  }

  @override
  Future<bool> isPrivacyGuardEnabled() async {
    return _prefs.getBool(LocalAuthConstants.privacyGuardEnabledKey) ?? true;
  }

  @override
  Future<void> setPrivacyGuardEnabled(bool enabled) async {
    await _prefs.setBool(LocalAuthConstants.privacyGuardEnabledKey, enabled);
    _settingsChangeController.add(null);
  }

  @override
  Future<int> getBackgroundLockTimeoutSeconds() async {
    return _prefs.getInt(LocalAuthConstants.backgroundLockTimeoutKey) ?? 0;
  }

  @override
  Future<void> setBackgroundLockTimeoutSeconds(int seconds) async {
    await _prefs.setInt(LocalAuthConstants.backgroundLockTimeoutKey, seconds);
    _settingsChangeController.add(null);
  }

  @override
  Future<int?> getLastBackgroundTime() async {
    return _prefs.getInt(LocalAuthConstants.lastBackgroundAtKey);
  }

  @override
  Future<void> setLastBackgroundTime(int timestampMillis) async {
    await _prefs.setInt(
        LocalAuthConstants.lastBackgroundAtKey, timestampMillis);
  }

  @override
  Future<void> clearLastBackgroundTime() async {
    await _prefs.remove(LocalAuthConstants.lastBackgroundAtKey);
  }

  @override
  Future<int?> getLockoutEndTime() async {
    return _prefs.getInt(LocalAuthConstants.lockoutEndKey);
  }

  @override
  Future<int> getLockoutLevel() async {
    return _prefs.getInt(LocalAuthConstants.lockoutLevelKey) ?? 0;
  }

  @override
  Future<void> saveLockoutState(int level, int endTime) async {
    await _prefs.setInt(LocalAuthConstants.lockoutLevelKey, level);
    await _prefs.setInt(LocalAuthConstants.lockoutEndKey, endTime);
  }

  @override
  Future<void> clearLockoutState() async {
    await _prefs.remove(LocalAuthConstants.lockoutLevelKey);
    await _prefs.remove(LocalAuthConstants.lockoutEndKey);
  }

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }
}
