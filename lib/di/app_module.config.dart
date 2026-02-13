// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:local_auth/local_auth.dart' as _i152;
import 'package:shared_preferences/shared_preferences.dart' as _i460;
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart'
    as _i314;
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/login/local_auth_login_bloc.dart'
    as _i197;
import 'package:unified_flutter_features/features/local_auth/presentation/bloc/settings/local_auth_settings_bloc.dart'
    as _i1022;

import '../core/services/ai_service.dart' as _i805;
import '../core/services/sound_service.dart' as _i173;
import '../features/categories/data/datasources/category_local_datasource.dart'
    as _i409;
import '../features/categories/data/repositories/category_repository_impl.dart'
    as _i346;
import '../features/categories/domain/repositories/category_repository.dart'
    as _i745;
import '../features/categories/domain/usecases/add_category.dart' as _i153;
import '../features/categories/domain/usecases/delete_category.dart' as _i932;
import '../features/categories/domain/usecases/get_categories.dart' as _i197;
import '../features/categories/presentation/bloc/category_bloc.dart' as _i393;
import '../features/journal/data/datasources/journal_local_datasource.dart'
    as _i417;
import '../features/journal/data/repositories/journal_repository_impl.dart'
    as _i531;
import '../features/journal/domain/repositories/journal_repository.dart'
    as _i303;
import '../features/journal/domain/usecases/add_entry.dart' as _i187;
import '../features/journal/domain/usecases/delete_entry.dart' as _i165;
import '../features/journal/domain/usecases/get_entries.dart' as _i423;
import '../features/journal/domain/usecases/search_entries.dart' as _i112;
import '../features/journal/presentation/bloc/journal_bloc.dart' as _i379;
import '../features/mindmap/data/datasources/mind_map_local_datasource.dart'
    as _i762;
import '../features/mindmap/data/repositories/mind_map_repository_impl.dart'
    as _i372;
import '../features/mindmap/domain/repositories/mind_map_repository.dart'
    as _i744;
import '../features/mindmap/presentation/bloc/mind_map_bloc.dart' as _i587;
import '../features/settings/presentation/bloc/settings_bloc.dart' as _i419;
import 'app_module.dart' as _i460;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final externalDependenciesModule = _$ExternalDependenciesModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => externalDependenciesModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i173.SoundService>(() => _i173.SoundService());
    gh.lazySingleton<_i152.LocalAuthentication>(
        () => externalDependenciesModule.localAuth);
    gh.lazySingleton<_i314.LocalAuthRepository>(() => externalDependenciesModule
        .localAuthRepository(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i762.MindMapLocalDataSource>(
        () => _i762.MindMapLocalDataSourceImpl());
    gh.factory<_i419.SettingsBloc>(
        () => _i419.SettingsBloc(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i805.AiService>(
        () => _i805.GeminiAiService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i409.CategoryLocalDataSource>(
        () => _i409.CategoryLocalDataSourceImpl());
    gh.lazySingleton<_i417.JournalLocalDataSource>(
        () => _i417.JournalLocalDataSourceImpl());
    gh.lazySingleton<_i744.MindMapRepository>(
        () => _i372.MindMapRepositoryImpl(gh<_i762.MindMapLocalDataSource>()));
    gh.lazySingleton<_i745.CategoryRepository>(() =>
        _i346.CategoryRepositoryImpl(gh<_i409.CategoryLocalDataSource>()));
    gh.factory<_i197.LocalAuthLoginBloc>(() => externalDependenciesModule
        .localAuthLoginBloc(gh<_i314.LocalAuthRepository>()));
    gh.factory<_i1022.LocalAuthSettingsBloc>(() => externalDependenciesModule
        .localAuthSettingsBloc(gh<_i314.LocalAuthRepository>()));
    gh.factory<_i587.MindMapBloc>(
        () => _i587.MindMapBloc(gh<_i744.MindMapRepository>()));
    gh.lazySingleton<_i303.JournalRepository>(
        () => _i531.JournalRepositoryImpl(gh<_i417.JournalLocalDataSource>()));
    gh.factory<_i932.DeleteCategory>(
        () => _i932.DeleteCategory(gh<_i745.CategoryRepository>()));
    gh.lazySingleton<_i197.GetCategories>(
        () => _i197.GetCategories(gh<_i745.CategoryRepository>()));
    gh.lazySingleton<_i153.AddCategory>(
        () => _i153.AddCategory(gh<_i745.CategoryRepository>()));
    gh.lazySingleton<_i423.GetEntries>(
        () => _i423.GetEntries(gh<_i303.JournalRepository>()));
    gh.lazySingleton<_i187.AddEntry>(
        () => _i187.AddEntry(gh<_i303.JournalRepository>()));
    gh.lazySingleton<_i112.SearchEntries>(
        () => _i112.SearchEntries(gh<_i303.JournalRepository>()));
    gh.factory<_i165.DeleteEntry>(
        () => _i165.DeleteEntry(gh<_i303.JournalRepository>()));
    gh.factory<_i393.CategoryBloc>(() => _i393.CategoryBloc(
          gh<_i197.GetCategories>(),
          gh<_i153.AddCategory>(),
          gh<_i932.DeleteCategory>(),
        ));
    gh.factory<_i379.JournalBloc>(() => _i379.JournalBloc(
          gh<_i423.GetEntries>(),
          gh<_i187.AddEntry>(),
          gh<_i112.SearchEntries>(),
          gh<_i165.DeleteEntry>(),
        ));
    return this;
  }
}

class _$ExternalDependenciesModule extends _i460.ExternalDependenciesModule {}
