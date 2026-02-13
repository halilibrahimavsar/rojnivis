import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:remote_auth_module/remote_auth_module.dart';

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
    getIt.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);
  }

  // Register Repository
  getIt.registerLazySingleton<AuthRepository>(() => FirebaseAuthRepository(
        auth: getIt<FirebaseAuth>(),
        firestore: getIt<FirebaseFirestore>(),
        createUserCollection: true,
      ));

  // Register BLoC
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(repository: getIt<AuthRepository>()),
  );
}
