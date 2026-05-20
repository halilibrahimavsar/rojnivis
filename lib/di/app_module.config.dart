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
import 'package:remote_auth_module/remote_auth_module.dart' as _i1041;
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
import '../features/insights/data/repositories/insights_repository_impl.dart'
    as _i646;
import '../features/insights/domain/repositories/insights_repository.dart'
    as _i584;
import '../features/insights/domain/usecases/get_insights.dart' as _i937;
import '../features/insights/presentation/bloc/insights_bloc.dart' as _i233;
import '../features/journal/data/datasources/entry_decoration_local_datasource.dart'
    as _i1064;
import '../features/journal/data/datasources/journal_local_datasource.dart'
    as _i417;
import '../features/journal/data/repositories/entry_decoration_repository_impl.dart'
    as _i700;
import '../features/journal/data/repositories/journal_repository_impl.dart'
    as _i531;
import '../features/journal/domain/repositories/entry_decoration_repository.dart'
    as _i796;
import '../features/journal/domain/repositories/journal_repository.dart'
    as _i303;
import '../features/journal/domain/usecases/add_entry.dart' as _i187;
import '../features/journal/domain/usecases/clear_stickers.dart' as _i880;
import '../features/journal/domain/usecases/delete_entry.dart' as _i165;
import '../features/journal/domain/usecases/get_entries.dart' as _i423;
import '../features/journal/domain/usecases/get_stickers.dart' as _i331;
import '../features/journal/domain/usecases/save_stickers.dart' as _i310;
import '../features/journal/domain/usecases/search_entries.dart' as _i112;
import '../features/journal/presentation/bloc/journal_bloc.dart' as _i379;
import '../features/settings/data/repositories/settings_repository_impl.dart'
    as _i1064;
import '../features/settings/domain/repositories/settings_repository.dart'
    as _i89;
import '../features/settings/domain/usecases/get_settings.dart' as _i463;
import '../features/settings/domain/usecases/update_settings.dart' as _i303;
import '../features/settings/presentation/bloc/settings_bloc.dart' as _i419;
import '../features/splash/presentation/bloc/splash_bloc.dart' as _i358;
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
    gh.lazySingleton<_i1064.EntryDecorationLocalDataSource>(
        () => _i1064.EntryDecorationLocalDataSourceImpl());
    gh.lazySingleton<_i805.AiService>(
        () => _i805.GeminiAiService(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i409.CategoryLocalDataSource>(
        () => _i409.CategoryLocalDataSourceImpl());
    gh.lazySingleton<_i417.JournalLocalDataSource>(
        () => _i417.JournalLocalDataSourceImpl());
    gh.lazySingleton<_i89.SettingsRepository>(
        () => _i1064.SettingsRepositoryImpl(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i796.EntryDecorationRepository>(() =>
        _i700.EntryDecorationRepositoryImpl(
            gh<_i1064.EntryDecorationLocalDataSource>()));
    gh.lazySingleton<_i745.CategoryRepository>(() =>
        _i346.CategoryRepositoryImpl(gh<_i409.CategoryLocalDataSource>()));
    gh.factory<_i197.LocalAuthLoginBloc>(() => externalDependenciesModule
        .localAuthLoginBloc(gh<_i314.LocalAuthRepository>()));
    gh.factory<_i1022.LocalAuthSettingsBloc>(() => externalDependenciesModule
        .localAuthSettingsBloc(gh<_i314.LocalAuthRepository>()));
    gh.lazySingleton<_i331.GetStickers>(
        () => _i331.GetStickers(gh<_i796.EntryDecorationRepository>()));
    gh.lazySingleton<_i310.SaveStickers>(
        () => _i310.SaveStickers(gh<_i796.EntryDecorationRepository>()));
    gh.lazySingleton<_i880.ClearStickers>(
        () => _i880.ClearStickers(gh<_i796.EntryDecorationRepository>()));
    gh.factory<_i358.SplashBloc>(() => _i358.SplashBloc(gh<_i1041.AuthBloc>()));
    gh.lazySingleton<_i303.JournalRepository>(
        () => _i531.JournalRepositoryImpl(gh<_i417.JournalLocalDataSource>()));
    gh.lazySingleton<_i463.GetSettings>(
        () => _i463.GetSettings(gh<_i89.SettingsRepository>()));
    gh.lazySingleton<_i303.UpdateSettings>(
        () => _i303.UpdateSettings(gh<_i89.SettingsRepository>()));
    gh.factory<_i932.DeleteCategory>(
        () => _i932.DeleteCategory(gh<_i745.CategoryRepository>()));
    gh.lazySingleton<_i197.GetCategories>(
        () => _i197.GetCategories(gh<_i745.CategoryRepository>()));
    gh.lazySingleton<_i153.AddCategory>(
        () => _i153.AddCategory(gh<_i745.CategoryRepository>()));
    gh.factory<_i419.SettingsBloc>(() => _i419.SettingsBloc(
          gh<_i463.GetSettings>(),
          gh<_i303.UpdateSettings>(),
        ));
    gh.lazySingleton<_i584.InsightsRepository>(
        () => _i646.InsightsRepositoryImpl(gh<_i303.JournalRepository>()));
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
    gh.lazySingleton<_i937.GetInsights>(
        () => _i937.GetInsights(gh<_i584.InsightsRepository>()));
    gh.factory<_i233.InsightsBloc>(
        () => _i233.InsightsBloc(gh<_i937.GetInsights>()));
    return this;
  }
}

class _$ExternalDependenciesModule extends _i460.ExternalDependenciesModule {}
