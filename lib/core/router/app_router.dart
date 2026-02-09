import 'package:go_router/go_router.dart';
import '../animations/page_flip_transition.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/add_entry_page.dart';
import '../../features/journal/presentation/pages/entry_detail_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/mindmap/presentation/pages/mind_map_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => PageFlipTransitionPage(
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
            pageBuilder: (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const CategoriesPage(),
            ),
          ),
          GoRoute(
            path: 'settings',
            pageBuilder: (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const SettingsPage(),
            ),
          ),
          GoRoute(
            path: 'mindmap',
            pageBuilder: (context, state) => PageFlipTransitionPage(
              key: state.pageKey,
              child: const MindMapPage(),
            ),
          ),
        ],
      ),
    ],
  );
}
