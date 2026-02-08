import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../../features/journal/presentation/pages/journal_page.dart';
import '../../features/journal/presentation/pages/add_entry_page.dart';
import '../../features/journal/presentation/pages/entry_detail_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const JournalPage(),
        routes: [
          GoRoute(
            path: 'add-entry',
            builder: (context, state) => const AddEntryPage(),
          ),
          GoRoute(
            path: 'entry/:entryId',
            pageBuilder: (context, state) {
              final entryId = state.pathParameters['entryId']!;
              return MaterialPage(
                key: state.pageKey,
                child: EntryDetailPage(entryId: entryId),
              );
            },
          ),
          GoRoute(
            path: 'categories',
            builder: (context, state) => const CategoriesPage(),
          ),
          GoRoute(
            path: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
        ],
      ),
    ],
  );
}
