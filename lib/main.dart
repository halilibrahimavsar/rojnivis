import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:rojnivis/core/services/ai_service.dart';
import 'package:rojnivis/firebase_options.dart';
import 'di/manual_auth_di.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_security_layer.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/error_handler.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'di/injection.dart';
import 'features/categories/data/models/category_model.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/journal/data/models/journal_entry_model.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/mindmap/domain/models/mind_map_node.dart';
import 'features/mindmap/presentation/bloc/mind_map_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

const String mindMapsBoxName = 'mind_maps';

/// Application entry point.
///
/// Initializes all required services and runs the app.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await _initializeApp();
    runApp(const RojnivisApp());
  } catch (error, stackTrace) {
    ErrorHandler.logError(error, stackTrace: stackTrace, context: 'main');
    // In a real app, you might want to show an error screen
    rethrow;
  }
}

/// Initializes all application services and dependencies.
///
/// This includes:
/// - Localization
/// - Hive storage
/// - Default data seeding
/// - Dependency injection
Future<void> _initializeApp() async {
  // Initialize localization
  await EasyLocalization.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();

  // Seed default data
  await _seedDefaultCategoriesIfEmpty();

  // Configure dependency injection
  await configureDependencies();
  registerAuthDependencies();

  // Initialize AI Service (Remote Config)
  try {
    await getIt<AiService>().init();
  } catch (e) {
    debugPrint('AI Service init failed: $e');
  }
}

/// Registers all Hive type adapters.
void _registerHiveAdapters() {
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(JournalEntryModelAdapter());
  Hive.registerAdapter(MindMapNodeAdapter());
}

/// Opens all required Hive boxes.
Future<void> _openHiveBoxes() async {
  await Hive.openBox<CategoryModel>(CategoryModel.boxName);
  await Hive.openBox<JournalEntryModel>(JournalEntryModel.boxName);
  await Hive.openBox<MindMapNode>(mindMapsBoxName);
}

/// Seeds default categories if the categories box is empty.
///
/// This ensures the app has some initial categories for users.
Future<void> _seedDefaultCategoriesIfEmpty() async {
  final box = Hive.box<CategoryModel>(CategoryModel.boxName);
  if (box.isNotEmpty) return;

  final defaultCategories = AppDefaults.defaultCategories.map(
    (data) => CategoryModel(
      id: data['id'] as String,
      name: data['name'] as String,
      color: data['color'] as int,
      iconPath: data['iconPath'] as String,
    ),
  );

  for (final category in defaultCategories) {
    await box.put(category.id, category);
  }
}

/// Root application widget.
///
/// Configures localization, theme, routing, and state management.
class RojnivisApp extends StatelessWidget {
  const RojnivisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      supportedLocales: const [
        Locale(AppDefaults.defaultLocale, AppDefaults.defaultCountryCode),
        Locale('en', 'US'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale(
        AppDefaults.defaultLocale,
        AppDefaults.defaultCountryCode,
      ),
      child: const _AppProviders(child: _AppConfiguration()),
    );
  }
}

/// Provides all BLoC instances to the widget tree.
class _AppProviders extends StatelessWidget {
  const _AppProviders({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<AuthBloc>()..add(const InitializeAuthEvent()),
        ),
        BlocProvider(
          create: (_) => getIt<SettingsBloc>()..add(const LoadSettings()),
        ),
        BlocProvider(
          create: (_) => getIt<JournalBloc>()..add(const LoadJournalEntries()),
        ),
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(const LoadCategories()),
        ),
        BlocProvider(
          create: (_) => getIt<MindMapBloc>()..add(const LoadMindMaps()),
        ),
      ],
      child: child,
    );
  }
}

/// Configures the MaterialApp with theme, localization, and routing.
class _AppConfiguration extends StatelessWidget {
  const _AppConfiguration();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = _extractSettings(state);

        if (settings.locale != null) {
          context.setLocale(settings.locale!);
        }

        return MaterialApp.router(
          title: 'Rojnivis',
          debugShowCheckedModeBanner: false,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.getLightTheme(
            settings.fontFamily,
            preset: settings.themePreset,
          ),
          darkTheme: AppTheme.getDarkTheme(
            settings.fontFamily,
            preset: settings.themePreset,
          ),
          themeMode: settings.themeMode,
          routerConfig: AppRouter.router,
          builder: (context, child) {
            return SafeArea(
              child: LocalAuthSecurityLayer(
                repository: getIt<LocalAuthRepository>(),
                child: child ?? const SizedBox.shrink(),
              ),
            );
          },
        );
      },
    );
  }

  /// Extracts settings from the state with defaults.
  _SettingsData _extractSettings(SettingsState state) {
    if (state is SettingsLoaded) {
      return _SettingsData(
        themeMode: state.themeMode,
        locale: state.locale,
        fontFamily: state.fontFamily,
        themePreset: state.themePreset,
      );
    }

    return const _SettingsData(
      themeMode: ThemeMode.system,
      locale: null,
      fontFamily: AppDefaults.defaultFontFamily,
      themePreset: AppDefaults.defaultThemePreset,
    );
  }
}

/// Immutable data class for application settings.
class _SettingsData {
  const _SettingsData({
    required this.themeMode,
    required this.locale,
    required this.fontFamily,
    required this.themePreset,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String fontFamily;
  final String themePreset;
}
