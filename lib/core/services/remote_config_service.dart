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
  Future<void> init() async {
    try {
      // Setup settings with a more reasonable timeout (10s instead of default 1m)
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 10),
          minimumFetchInterval: const Duration(
            hours: 1,
          ), // Reduced for fresher config
        ),
      );

      await _remoteConfig.setDefaults(const {
        _serverClientIdKey: _fallbackServerClientId,
      });

      // Attempt to fetch and activate.
      // This will use the 10s timeout configured above.
      final activated = await _remoteConfig.fetchAndActivate();

      debugPrint('Remote Config fetched and activated: $activated');
      debugPrint(
        'Remote Config serverClientId resolved: '
        '${serverClientId.substring(0, 12)}...',
      );
    } catch (e) {
      debugPrint('Failed to initialize Remote Config: $e');
      // We don't rethrow here because the app can still function with defaults
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
