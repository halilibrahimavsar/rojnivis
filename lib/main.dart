import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:rojnivis/core/services/remote_config_service.dart';
import 'package:rojnivis/core/services/ai_service.dart';
import 'package:rojnivis/firebase_options.dart';
import 'di/manual_auth_di.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_security_layer.dart';
import 'package:rojnivis/core/services/notification_service.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'core/constants/app_constants.dart';
import 'core/errors/error_handler.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/page_studio_models.dart';
import 'di/injection.dart';
import 'features/categories/data/models/category_model.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/insights/presentation/bloc/insights_bloc.dart';
import 'features/journal/data/models/journal_entry_model.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/calendar/data/models/reminder_dto.dart';
import 'features/calendar/presentation/bloc/calendar_bloc.dart';
import 'features/calendar/presentation/bloc/calendar_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/splash/presentation/bloc/splash_bloc.dart';

/// Application entry point.
///
/// Initializes all required services and runs the app.
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

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
  // Start parallel execution of critical services
  await Future.wait([
    EasyLocalization.ensureInitialized(),
    Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform),
    _initHiveAndSeed(),
    NotificationService().init(),
  ]);

  // Non-blocking background tasks
  unawaited(_initBackgroundServices());

  // Wait for critical DI
  await Future.any([
    _initializeCriticalServices(),
    Future.delayed(const Duration(seconds: 10)).then((_) {
      debugPrint(
        'WARNING: Critical initialization timed out after 10s. Proceeding...',
      );
    }),
  ]);
}

Future<void> _initHiveAndSeed() async {
  await Hive.initFlutter();
  _registerHiveAdapters();
  await _openHiveBoxes();
  await _seedDefaultCategoriesIfEmpty();
}

Future<void> _initBackgroundServices() async {
  try {
    await FirebaseAnalytics.instance.logAppOpen();
    debugPrint('Firebase Analytics initialized');
  } catch (e) {
    debugPrint('Firebase Analytics initialization failed: $e');
  }

  try {
    await NotificationService().requestPermissions();
  } catch (e) {
    debugPrint('Notification permissions failed: $e');
  }
}

Future<void> _initializeCriticalServices() async {
  final remoteConfig = RemoteConfigService();
  if (!getIt.isRegistered<RemoteConfigService>()) {
    getIt.registerLazySingleton<RemoteConfigService>(() => remoteConfig);
  }

  // Register auth dependencies immediately using the hardcoded fallback
  // serverClientId — RemoteConfig fetch runs in parallel so it doesn't
  // block startup. If RC resolves before auth is first used, the value
  // will be up-to-date. If not, the hardcoded fallback is always valid.
  registerAuthDependencies();

  // Configure generated DI (SharedPreferences, LocalAuth, etc.)
  await configureDependencies();

  // Fetch Remote Config and AI init in the background — both are non-critical
  // for the initial render and have their own internal timeouts.
  unawaited(
    remoteConfig.init().catchError((Object e) {
      debugPrint('Remote Config background init failed: $e');
    }),
  );
  unawaited(
    getIt<AiService>().init().catchError((Object e) {
      debugPrint('AI Service background init failed: $e');
    }),
  );
}

/// Registers all Hive type adapters.
void _registerHiveAdapters() {
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(JournalEntryModelAdapter());
  Hive.registerAdapter(ReminderDtoAdapter());
}

/// Opens all required Hive boxes.
Future<void> _openHiveBoxes() async {
  await Hive.openBox<CategoryModel>(CategoryModel.boxName);
  await Hive.openBox<JournalEntryModel>(JournalEntryModel.boxName);
  await Hive.openBox<String>(StorageKeys.entryDecorationsBox);
  await Hive.openBox<ReminderDto>(StorageKeys.remindersBox);
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
          create: (_) => getIt<InsightsBloc>()..add(const LoadInsights()),
        ),
        BlocProvider(
          create: (_) => getIt<JournalBloc>()..add(const LoadJournalEntries()),
        ),
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(const LoadCategories()),
        ),
        BlocProvider(
          create:
              (_) =>
                  getIt<CalendarBloc>()
                    ..add(LoadCalendarData(month: DateTime.now())),
        ),
        BlocProvider(
          create: (_) => getIt<SplashBloc>()..add(const InitializeSplash()),
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
            pageVisualFamily: PageVisualFamilyX.fromId(
              settings.pageVisualFamily,
            ),
            vintagePaperVariant: VintagePaperVariantX.fromId(
              settings.vintagePaperVariant,
            ),
            animationIntensity: AnimationIntensityX.fromId(
              settings.animationIntensity,
            ),
          ),
          darkTheme: AppTheme.getDarkTheme(
            settings.fontFamily,
            preset: settings.themePreset,
            pageVisualFamily: PageVisualFamilyX.fromId(
              settings.pageVisualFamily,
            ),
            vintagePaperVariant: VintagePaperVariantX.fromId(
              settings.vintagePaperVariant,
            ),
            animationIntensity: AnimationIntensityX.fromId(
              settings.animationIntensity,
            ),
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
        themeMode: state.settings.themeMode,
        locale: state.settings.locale,
        fontFamily: state.settings.fontFamily,
        themePreset: state.effectiveThemePreset,
        pageVisualFamily: state.settings.pageVisualFamily,
        vintagePaperVariant: state.settings.vintagePaperVariant,
        animationIntensity: state.settings.animationIntensity,
      );
    }

    return const _SettingsData(
      themeMode: ThemeMode.system,
      locale: null,
      fontFamily: AppDefaults.defaultFontFamily,
      themePreset: AppDefaults.defaultThemePreset,
      pageVisualFamily: AppDefaults.defaultPageVisualFamily,
      vintagePaperVariant: AppDefaults.defaultVintagePaperVariant,
      animationIntensity: AppDefaults.defaultAnimationIntensity,
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
    required this.pageVisualFamily,
    required this.vintagePaperVariant,
    required this.animationIntensity,
  });

  final ThemeMode themeMode;
  final Locale? locale;
  final String fontFamily;
  final String themePreset;
  final String pageVisualFamily;
  final String vintagePaperVariant;
  final String animationIntensity;
}
