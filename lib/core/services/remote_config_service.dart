import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

/// Service to handle application configuration via Firebase Remote Config.
class RemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  /// Remote Config keys
  static const String _serverClientIdKey = 'server_client_id';

  /// Hardcoded fallback — used when Remote Config hasn't fetched yet or
  /// returns empty. This is the Web Client ID from the Google Cloud Console.
  static const String _fallbackServerClientId =
      '628938091989-k01fs57t6up2qbepdvk8p39nt7n6j0q7.apps.googleusercontent.com';

  /// Initializes Remote Config with default values and fetches latest values.
  ///
  /// Never throws — the app always falls back to [_fallbackServerClientId].
  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          // 5s is enough for a healthy connection; on cold start with slow
          // connectivity this still completes within the 10s main-thread window.
          fetchTimeout: const Duration(seconds: 5),
          minimumFetchInterval: const Duration(hours: 1),
        ),
      );

      await _remoteConfig.setDefaults(const {
        _serverClientIdKey: _fallbackServerClientId,
      });

      // fetchAndActivate may return false on a cached response — that is fine.
      final activated = await _remoteConfig.fetchAndActivate();

      debugPrint('Remote Config fetched and activated: $activated');
      debugPrint(
        'Remote Config serverClientId resolved: '
        '${serverClientId.substring(0, 12)}...',
      );
    } on Exception catch (e) {
      // Non-fatal: the fallback value is always returned from [serverClientId].
      debugPrint('RemoteConfigService.init failed (using defaults): $e');
    }
  }

  /// Gets the Google Server Client ID for authentication.
  ///
  /// Returns the Remote Config value if non-empty, otherwise falls back
  /// to the hardcoded default. Never returns empty — google_sign_in v7
  /// throws if serverClientId is empty on Android.
  String get serverClientId {
    final value = _remoteConfig.getString(_serverClientIdKey);
    if (value.isNotEmpty) return value;
    return _fallbackServerClientId;
  }
}
