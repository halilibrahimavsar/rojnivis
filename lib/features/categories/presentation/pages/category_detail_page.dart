import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../../../journal/domain/entities/journal_entry.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';
import '../../../../core/widgets/themed_paper.dart';
import 'categories_page.dart';

class CategoryDetailPage extends StatelessWidget {
  const CategoryDetailPage({super.key, required this.categoryId});

  final String categoryId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      extendBody: true,
      body: Stack(
        children: [
          const Positioned.fill(
            child: ThemedBackdrop(
              blurSigma: 6,
              opacity: 0.95,
              applyPageStudio: true,
            ),
          ),
          BlocBuilder<CategoryBloc, CategoryState>(
            builder: (context, categoryState) {
              if (categoryState is CategoryLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (categoryState is CategoryError) {
                return Center(child: Text(categoryState.message));
              }

              final categories =
                  categoryState is CategoryLoaded
                      ? categoryState.categories
                      : <Category>[];
              final Category? currentCategory = categories
                  .cast<Category?>()
                  .firstWhere((c) => c?.id == categoryId, orElse: () => null);

              if (currentCategory == null) {
                return Scaffold(
                  appBar: AppBar(title: Text('error'.tr())),
                  body: Center(child: Text('category_not_found'.tr())),
                );
              }

              final subCategories =
                  categories.where((c) => c.parentId == categoryId).toList();

              return BlocBuilder<JournalBloc, JournalState>(
                builder: (context, journalState) {
                  final journalEntries =
                      journalState is JournalLoaded
                          ? journalState.entries
                          : <JournalEntry>[];

                  final categoryEntries =
                      journalEntries
                          .where((e) => e.categoryId == categoryId)
                          .toList();

                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        title: Text(currentCategory.name),
                        floating: true,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                      ),
                      if (subCategories.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'sub_categories'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final c = subCategories[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCategoryTile(
                                  category: c,
                                  allCategories: categories,
                                  journalEntries: journalEntries,
                                  isSubcategory: true,
                                  onEdit: (cat) {
                                    // Editing from detail page is restricted to prevent duplicate logic.
                                    // Users can edit from the main categories page.
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Edit from main categories page',
                                        ),
                                      ),
                                    );
                                  },
                                  onDelete: (cat) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Delete from main categories page',
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }, childCount: subCategories.length),
                          ),
                        ),
                      ],
                      if (categoryEntries.isNotEmpty) ...[
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              'entries'.tr(),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final entry = categoryEntries[index];
                              final formattedDate = DateFormat.yMMMMd(
                                context.locale.languageCode,
                              ).format(entry.date);
                              final theme = Theme.of(context);

                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: theme.colorScheme.surfaceContainerHighest
                                    .withValues(alpha: 0.3),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: theme.colorScheme.outlineVariant
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Color(
                                      currentCategory.color,
                                    ).withValues(alpha: 0.15),
                                    child: Text(
                                      entry.mood.emoji,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                  ),
                                  title: Text(
                                    entry.title.isEmpty
                                        ? 'untitled'.tr()
                                        : entry.title,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    formattedDate,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                  ),
                                  onTap: () {
                                    context.push('/home/entry/${entry.id}');
                                  },
                                ),
                              );
                            }, childCount: categoryEntries.length),
                          ),
                        ),
                      ],
                      if (subCategories.isEmpty && categoryEntries.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.folder_open_outlined,
                                  size: 48,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.primary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'empty_category'.tr(),
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium?.copyWith(
                                    color:
                                        Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
