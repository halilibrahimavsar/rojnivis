import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';

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
  // We'll register LocalAuthRepository separately for now
  // until unified_flutter_features is properly set up
}
