import 'package:go_router/go_router.dart';
import '../animations/page_flip_transition.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/add_entry_page.dart';
import '../../features/journal/presentation/pages/entry_detail_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/mindmap/presentation/pages/mind_map_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';

import 'package:remote_auth_module/remote_auth_module.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => PageFlipTransitionPage(
          key: state.pageKey,
          child: const SplashPage(),
        ),
      ),
      GoRoute(
        path: '/home',
        pageBuilder:
            (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const JournalPage(),
            ),
        routes: [
          GoRoute(
            path: 'add-entry',
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
                (context, state) => PageFlipTransitionPage(
                  key: state.pageKey,
                  child: const CategoriesPage(),
                ),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder:
                (context, state) => PageFlipTransitionPage(
                  key: state.pageKey,
                  child: const SettingsPage(),
                ),
          ),
          GoRoute(
            path: 'mindmap',
            pageBuilder:
                (context, state) => PageFlipTransitionPage(
                  key: state.pageKey,
                  child: const MindMapPage(),
                ),
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
