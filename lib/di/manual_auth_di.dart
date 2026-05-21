import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'package:remote_auth_module/remote_auth_module.dart';

import '../core/services/remote_config_service.dart';
import '../firebase_options.dart';
import 'injection.dart';

/// Manually registers Auth module dependencies.
///
/// This is used because we cannot run build_runner in the current environment
/// to generate injectable code.
void registerAuthDependencies() {
  // Register FirebaseAuth if not already registered
  if (!getIt.isRegistered<FirebaseAuth>()) {
    getIt.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  }

  // Register FirebaseFirestore if not already registered
  if (!getIt.isRegistered<FirebaseFirestore>()) {
    getIt.registerLazySingleton<FirebaseFirestore>(
      () => FirebaseFirestore.instance,
    );
  }

  // Register RemoteConfigService if not already registered
  if (!getIt.isRegistered<RemoteConfigService>()) {
    getIt.registerLazySingleton<RemoteConfigService>(
      () => RemoteConfigService(),
    );
  }

  // Platform-aware OAuth client IDs:
  // - Android: needs serverClientId (Web Client ID) for native Google Sign-In
  // - Web: needs clientId for signInWithPopup flow
  // - iOS/macOS: reads CLIENT_ID from GoogleService-Info.plist automatically
  final serverClientId = getIt<RemoteConfigService>().serverClientId;
  final webClientId =
      kIsWeb ? DefaultFirebaseOptions.web.apiKey : null; // Not needed on mobile

  // Register Repository
  getIt.registerLazySingleton<AuthRepository>(
    () => FirebaseAuthRepository(
      auth: getIt<FirebaseAuth>(),
      firestore: getIt<FirebaseFirestore>(),
      // Firestore user document sync is disabled until a Firestore database
      // is provisioned in the Firebase console for this project.
      // See: https://console.cloud.google.com/firestore/databases?project=rojnivis
      // Re-enable by setting createUserCollection: true once ready.
      createUserCollection: false,
      serverClientId: serverClientId,
      clientId: webClientId,
    ),
  );
}
