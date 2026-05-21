import 'dart:async';
import 'dart:ui';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/category.dart';
import '../bloc/category_bloc.dart';
import '../../../journal/domain/entities/journal_entry.dart';
import '../../../journal/presentation/bloc/journal_bloc.dart';

const List<Color> _categoryColorOptions = [
  Color(0xFF6C5CE7),
  Color(0xFF00CEC9),
  Color(0xFFFD79A8),
  Color(0xFF0984E3),
  Color(0xFF00B894),
  Color(0xFFFF7675),
  Color(0xFFFDCB6E),
  Color(0xFF2D3436),
];

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _openEditor(
    BuildContext context,
    List<Category> allCategories, {
    Category? existing,
  }) async {
    final result = await showDialog<Category>(
      context: context,
      builder:
          (context) => _CategoryEditorDialog(
            existing: existing,
            allCategories: allCategories,
          ),
    );

    if (!context.mounted) return;
    if (result == null) return;
    context.read<CategoryBloc>().add(UpsertCategoryRequested(category: result));
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('delete_category'.tr()),
                content: Text('delete_category_confirm'.tr()),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('cancel'.tr()),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('delete'.tr()),
                  ),
                ],
              ),
        ) ??
        false;
  }

  // _showFolderDetailsSheet removed to use full page navigation

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: Text('categories'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, categoryState) {
          if (categoryState is CategoryInitial ||
              categoryState is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (categoryState is CategoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(categoryState.message, textAlign: TextAlign.center),
              ),
            );
          }

          final categories = (categoryState as CategoryLoaded).categories;
          if (categories.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.category_outlined,
                      size: 44,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'empty_categories'.tr(),
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => _openEditor(context, categories),
                      icon: const Icon(Icons.add),
                      label: Text('add_category'.tr()),
                    ),
                  ],
                ),
              ),
            );
          }

          return BlocBuilder<JournalBloc, JournalState>(
            builder: (context, journalState) {
              final journalEntries =
                  journalState is JournalLoaded
                      ? journalState.entries
                      : <JournalEntry>[];

              final rootCategories =
                  categories.where((c) => c.parentId == null).toList();

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                itemCount: rootCategories.length,
                separatorBuilder:
                    (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final c = rootCategories[index];
                  return GlassCategoryTile(
                    category: c,
                    allCategories: categories,
                    journalEntries: journalEntries,
                    onEdit:
                        (cat) =>
                            _openEditor(context, categories, existing: cat),
                    onDelete: (cat) async {
                      final shouldDelete = await _confirmDelete(context);
                      if (!context.mounted) return;
                      if (shouldDelete) {
                        context.read<CategoryBloc>().add(
                          DeleteCategoryRequested(categoryId: cat.id),
                        );
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('deleted'.tr())));
                      }
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0),
        child: FloatingActionButton.extended(
          onPressed: () {
            final state = context.read<CategoryBloc>().state;
            final categoriesList =
                state is CategoryLoaded ? state.categories : <Category>[];
            _openEditor(context, categoriesList);
          },
          icon: const Icon(Icons.add),
          label: Text('add_category'.tr()),
        ),
      ),
    );
  }
}

class GlassCategoryTile extends StatefulWidget {
  const GlassCategoryTile({
    super.key,
    required this.category,
    required this.allCategories,
    required this.journalEntries,
    required this.onEdit,
    required this.onDelete,
    this.isSubcategory = false,
  });

  final Category category;
  final List<Category> allCategories;
  final List<JournalEntry> journalEntries;
  final void Function(Category) onEdit;
  final void Function(Category) onDelete;
  final bool isSubcategory;

  @override
  State<GlassCategoryTile> createState() => _GlassCategoryTileState();
}

class _GlassCategoryTileState extends State<GlassCategoryTile> {
  bool _isExpanded = false;

  String _formatCount(int count, String langCode) {
    if (langCode.startsWith('tr')) {
      return '$count kayıt';
    }
    return '$count ${count == 1 ? 'entry' : 'entries'}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final catColor = Color(widget.category.color);

    final subcategories =
        widget.allCategories
            .where((c) => c.parentId == widget.category.id)
            .toList();

    final categoryEntries =
        widget.journalEntries
            .where((e) => e.categoryId == widget.category.id)
            .toList();

    final hasChildren = subcategories.isNotEmpty;

    return Padding(
      padding:
          widget.isSubcategory
              ? const EdgeInsets.only(top: 8)
              : EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              color:
                  isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: catColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Theme(
              data: theme.copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                initiallyExpanded: _isExpanded,
                onExpansionChanged: (expanded) {
                  setState(() => _isExpanded = expanded);
                },
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    hasChildren
                        ? Icons.folder_open_rounded
                        : Icons.category_rounded,
                    color: catColor,
                    size: 24,
                  ),
                ),
                title: Text(
                  widget.category.name,
                  style: TextStyle(
                    fontFamily: GoogleFonts.patrickHand().fontFamily,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  _formatCount(
                    categoryEntries.length,
                    context.locale.languageCode,
                  ),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                      ),
                      onPressed: () {
                        context.push('/home/category/${widget.category.id}');
                      },
                      tooltip: 'open_category'.tr(),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onSelected: (value) {
                        if (value == 'edit') widget.onEdit(widget.category);
                        if (value == 'delete') widget.onDelete(widget.category);
                      },
                      itemBuilder:
                          (context) => [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text('edit'.tr()),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                'delete'.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                    ),
                  ],
                ),
                children: [
                  if (hasChildren)
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 48,
                        right: 16,
                        bottom: 12,
                      ),
                      child: Column(
                        children:
                            subcategories.map((subCat) {
                              return GlassCategoryTile(
                                category: subCat,
                                allCategories: widget.allCategories,
                                journalEntries: widget.journalEntries,
                                isSubcategory: true,
                                onEdit: widget.onEdit,
                                onDelete: widget.onDelete,
                              );
                            }).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.existing, required this.allCategories});

  final Category? existing;
  final List<Category> allCategories;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late int _selectedColor;
  String? _selectedParentId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor =
        widget.existing?.color ?? _categoryColorOptions.first.toARGB32();
    _selectedParentId = widget.existing?.parentId;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final maxHeight = MediaQuery.of(context).size.height * 0.6;

    return AlertDialog(
      title: Text(isEditing ? 'edit_category'.tr() : 'add_category'.tr()),
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'category_name'.tr(),
                  prefixIcon: const Icon(Icons.category_outlined),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                value: _selectedParentId,
                decoration: InputDecoration(
                  labelText: 'parent_category'.tr(),
                  prefixIcon: const Icon(Icons.folder_outlined),
                ),
                items: [
                  DropdownMenuItem(value: null, child: Text('no_parent'.tr())),
                  ...widget.allCategories
                      .where(
                        (c) => c.id != widget.existing?.id,
                      ) // Prevent self-parenting
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      ),
                ],
                onChanged: (val) => setState(() => _selectedParentId = val),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'color'.tr(),
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in _categoryColorOptions)
                    InkWell(
                      onTap: () {
                        setState(() => _selectedColor = color.toARGB32());
                      },
                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color:
                                _selectedColor == color.toARGB32()
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child:
                            _selectedColor == color.toARGB32()
                                ? const Icon(
                                  Icons.check,
                                  size: 18,
                                  color: Colors.white,
                                )
                                : null,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final name = _nameController.text.trim();
            if (name.isEmpty) return;
            Navigator.of(context).pop(
              Category(
                id: widget.existing?.id ?? const Uuid().v4(),
                name: name,
                color: _selectedColor,
                iconPath: widget.existing?.iconPath ?? '',
                parentId: _selectedParentId,
              ),
            );
          },
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
