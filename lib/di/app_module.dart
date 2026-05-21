import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/data/secure_local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart';

import 'package:local_auth/local_auth.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:http/http.dart' as http;
import 'package:remote_auth_module/remote_auth_module.dart';
import 'injection.config.dart';

final getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();

// External dependencies module
@module
abstract class ExternalDependenciesModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  LocalAuthentication get localAuth => LocalAuthentication();

  // Local Auth Repository
  @lazySingleton
  LocalAuthRepository localAuthRepository(SharedPreferences prefs) {
    return SecureLocalAuthRepository(prefs: prefs);
  }

  // Local Auth Login Bloc
  @injectable
  LocalAuthLoginBloc localAuthLoginBloc(LocalAuthRepository repository) {
    return LocalAuthLoginBloc(repository: repository);
  }

  // Local Auth Settings Bloc
  @injectable
  LocalAuthSettingsBloc localAuthSettingsBloc(LocalAuthRepository repository) {
    return LocalAuthSettingsBloc(repository: repository);
  }

  // Firebase Remote Config
  @lazySingleton
  FirebaseRemoteConfig get firebaseRemoteConfig =>
      FirebaseRemoteConfig.instance;

  // HTTP Client
  @lazySingleton
  http.Client get httpClient => http.Client();

  // Auth Bloc
  @lazySingleton
  AuthBloc get authBloc => AuthBloc(repository: getIt<AuthRepository>());
}
