import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'di/injection.dart';
import 'features/categories/data/models/category_model.dart';
import 'features/categories/presentation/bloc/category_bloc.dart';
import 'features/journal/data/models/journal_entry_model.dart';
import 'features/journal/presentation/bloc/journal_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(CategoryModelAdapter());
  Hive.registerAdapter(JournalEntryModelAdapter());

  await configureDependencies();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('tr', 'TR'), Locale('en', 'US')],
      path: 'assets/translations',
      fallbackLocale: const Locale('tr', 'TR'),
      child: const RojnivisApp(),
    ),
  );
}

class RojnivisApp extends StatelessWidget {
  const RojnivisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<SettingsBloc>()..add(LoadSettings())),
        BlocProvider(
          create: (_) => getIt<JournalBloc>()..add(LoadJournalEntries()),
        ),
        BlocProvider(
          create: (_) => getIt<CategoryBloc>()..add(LoadCategories()),
        ),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          ThemeMode themeMode = ThemeMode.system;
          Locale? locale;
          String fontFamily = 'Poppins';

          if (state is SettingsLoaded) {
            themeMode = state.themeMode;
            locale = state.locale;
            fontFamily = state.fontFamily;
            context.setLocale(locale);
          }

          return MaterialApp.router(
            title: 'Rojnivis',
            debugShowCheckedModeBanner: false,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            theme: AppTheme.getLightTheme(fontFamily),
            darkTheme: AppTheme.getDarkTheme(fontFamily),
            themeMode: themeMode,
            routerConfig: AppRouter.router,
          );
        },
      ),
    );
  }
}
