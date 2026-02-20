import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../animations/page_flip_transition.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/add_entry_page.dart';
import '../../features/journal/presentation/pages/entry_detail_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/calendar/presentation/pages/calendar_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/page_studio_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../../features/settings/presentation/pages/local_auth_settings_page.dart';
import '../../features/settings/presentation/pages/remote_auth_settings_page.dart';

import 'package:remote_auth_module/remote_auth_module.dart';
import '../widgets/app_layout.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'shell',
);

class AppRouter {
  static final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder:
            (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const SplashPage(),
            ),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppLayout(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            pageBuilder:
                (context, state) => CustomTransitionPage(
                  key: state.pageKey,
                  child: const JournalPage(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                ),
            routes: [
              GoRoute(
                path: 'add-entry',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final entryId = state.uri.queryParameters['entryId'];
                  return PageFlipTransitionPage(
                    key: state.pageKey,
                    child: AddEntryPage(entryId: entryId),
                  );
                },
              ),
              GoRoute(
                path: 'entry/:entryId',
                parentNavigatorKey: _rootNavigatorKey,
                pageBuilder: (context, state) {
                  final entryId = state.pathParameters['entryId']!;
                  return PageFlipTransitionPage(
                    key: state.pageKey,
                    child: EntryDetailPage(entryId: entryId),
                  );
                },
              ),
              GoRoute(
                path: 'categories',
                pageBuilder:
                    (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const CategoriesPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                    ),
              ),
              GoRoute(
                path: 'calendar',
                pageBuilder:
                    (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const CalendarPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                    ),
              ),
              GoRoute(
                path: 'settings',
                pageBuilder:
                    (context, state) => CustomTransitionPage(
                      key: state.pageKey,
                      child: const SettingsPage(),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) =>
                              FadeTransition(opacity: animation, child: child),
                    ),
                routes: [
                  GoRoute(
                    path: 'local-auth',
                    pageBuilder:
                        (context, state) => PageFlipTransitionPage(
                          key: state.pageKey,
                          child: const LocalAuthSettingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'remote-auth',
                    pageBuilder:
                        (context, state) => PageFlipTransitionPage(
                          key: state.pageKey,
                          child: const RemoteAuthSettingsPage(),
                        ),
                  ),
                  GoRoute(
                    path: 'page-studio',
                    pageBuilder:
                        (context, state) => PageFlipTransitionPage(
                          key: state.pageKey,
                          child: const PageStudioPage(),
                        ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/public',
        pageBuilder:
            (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: LoginPage(
                onRegisterTap: () => context.push('/register'),
                onForgotPasswordTap: () => context.push('/forgot_paswd'),
                onAuthenticated: (user) => context.go('/home'),
              ),
            ),
      ),
      GoRoute(
        path: '/register',
        pageBuilder:
            (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: RegisterPage(
                onLoginTap: () => context.pop(),
                onRegistered: (user) => context.go('/home'),
              ),
            ),
      ),
      GoRoute(
        path: '/forgot_paswd',
        pageBuilder:
            (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const ForgotPasswordPage(),
            ),
      ),
    ],
  );
}
