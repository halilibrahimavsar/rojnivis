import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/glass_overlays.dart';
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

  Future<void> _openEditor(BuildContext context, {Category? existing}) async {
    final result = await showDialog<Category>(
      context: context,
      builder: (context) => _CategoryEditorDialog(existing: existing),
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

  void _showContextMenu(BuildContext context, Category category) {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(category.name),
            content: Text('category'.tr()),
            actions: [
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  _openEditor(context, existing: category);
                },
                icon: const Icon(Icons.edit_outlined),
                label: Text('edit'.tr()),
              ),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  final shouldDelete = await _confirmDelete(context);
                  if (!context.mounted) return;
                  if (shouldDelete) {
                    context.read<CategoryBloc>().add(
                      DeleteCategoryRequested(categoryId: category.id),
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('deleted'.tr())));
                  }
                },
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                label: Text(
                  'delete'.tr(),
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showFolderDetailsSheet({
    required BuildContext context,
    required Category category,
    required List<JournalEntry> entries,
  }) {
    final theme = Theme.of(context);
    final folderColor = Color(category.color);
    final locale = context.locale.toString();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (context, scrollController) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          color: folderColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: folderColor.withValues(alpha: 0.4),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _formatEntriesCount(
                                entries.length,
                                context.locale.languageCode,
                              ),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'edit'.tr(),
                        onPressed: () {
                          Navigator.pop(context);
                          _openEditor(context, existing: category);
                        },
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.delete_outline,
                          color: theme.colorScheme.error,
                        ),
                        tooltip: 'delete'.tr(),
                        onPressed: () async {
                          final shouldDelete = await _confirmDelete(context);
                          if (!context.mounted) return;
                          if (shouldDelete) {
                            Navigator.pop(context);
                            context.read<CategoryBloc>().add(
                              DeleteCategoryRequested(categoryId: category.id),
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('deleted'.tr())),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  Expanded(
                    child:
                        entries.isEmpty
                            ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(24.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open_outlined,
                                      size: 48,
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      'empty_journal'.tr(),
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            color:
                                                theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                          ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    FilledButton.icon(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        context.push('/home/add-entry');
                                      },
                                      icon: const Icon(Icons.add),
                                      label: Text('create_entry'.tr()),
                                    ),
                                  ],
                                ),
                              ),
                            )
                            : ListView.separated(
                              controller: scrollController,
                              itemCount: entries.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final entry = entries[index];
                                final formattedDate = DateFormat.yMMMMd(
                                  locale,
                                ).format(entry.date);

                                return Card(
                                  margin: EdgeInsets.zero,
                                  elevation: 0,
                                  color: theme
                                      .colorScheme
                                      .surfaceContainerHighest
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
                                      backgroundColor: folderColor.withValues(
                                        alpha: 0.15,
                                      ),
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
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.arrow_forward_ios,
                                      size: 14,
                                    ),
                                    onTap: () {
                                      Navigator.pop(context);
                                      context.push('/home/entry/${entry.id}');
                                    },
                                  ),
                                );
                              },
                            ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  String _formatEntriesCount(int count, String langCode) {
    if (langCode.startsWith('tr')) {
      return '$count kayıt';
    }
    return '$count ${count == 1 ? 'entry' : 'entries'}';
  }

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
                      onPressed: () => _openEditor(context),
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

              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 18,
                  mainAxisSpacing: 22,
                  childAspectRatio: 0.92,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  final categoryEntries =
                      journalEntries
                          .where((e) => e.categoryId == c.id)
                          .toList();

                  return SkeuomorphicFolderCard(
                    category: c,
                    entryCount: categoryEntries.length,
                    onTap: () {
                      _showFolderDetailsSheet(
                        context: context,
                        category: c,
                        entries: categoryEntries,
                      );
                    },
                    onLongPress: () {
                      _showContextMenu(context, c);
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
          onPressed: () => _openEditor(context),
          icon: const Icon(Icons.add),
          label: Text('add_category'.tr()),
        ),
      ),
    );
  }
}

class SkeuomorphicFolderCard extends StatefulWidget {
  const SkeuomorphicFolderCard({
    super.key,
    required this.category,
    required this.entryCount,
    required this.onTap,
    required this.onLongPress,
  });

  final Category category;
  final int entryCount;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  State<SkeuomorphicFolderCard> createState() => _SkeuomorphicFolderCardState();
}

class _SkeuomorphicFolderCardState extends State<SkeuomorphicFolderCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final folderColor = Color(widget.category.color);

    final papersTop = _isHovered ? 12.0 : 24.0;
    final papersRotation = _isHovered ? -0.03 : -0.015;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isPressed ? 0.96 : (_isHovered ? 1.04 : 1.0),
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOutBack,
          child: SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: ClipPath(
                    clipper: const FolderBackClipper(
                      tabHeight: 20,
                      tabWidth: 65,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        color: folderColor,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            folderColor,
                            folderColor.withValues(alpha: 0.8),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.15,
                            ),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  top: papersTop,
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: AnimatedRotation(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    turns: papersRotation,
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            isDark ? Colors.grey[850] : const Color(0xFFFFFDF2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              isDark
                                  ? Colors.grey[700]!
                                  : const Color(0xFFE8E5D3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (int i = 0; i < 4; i++)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              height: 1,
                              color:
                                  isDark
                                      ? Colors.grey[700]
                                      : Colors.blue.withValues(alpha: 0.1),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 36,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: folderColor,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          folderColor.withValues(alpha: 0.95),
                          folderColor.withValues(alpha: 0.85),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.35 : 0.18,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Container(
                            height: 1,
                            color: Colors.black.withValues(alpha: 0.1),
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 10,
                          child: Container(
                            height: 1.5,
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        Positioned(
                          top: 22,
                          left: 12,
                          right: 12,
                          child: Transform.rotate(
                            angle: 0.02,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? Colors.grey[900]
                                        : const Color(0xFFFBF9EE),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color:
                                      isDark
                                          ? Colors.grey[800]!
                                          : const Color(0xFFEFECCF),
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 2,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                widget.category.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily:
                                      GoogleFonts.patrickHand().fontFamily,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      isDark
                                          ? Colors.grey[200]
                                          : const Color(0xFF5D4037),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.15),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _formatCount(
                                widget.entryCount,
                                context.locale.languageCode,
                              ),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 12,
                          child: Icon(
                            Icons.folder_open,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCount(int count, String langCode) {
    if (langCode.startsWith('tr')) {
      return '$count kayıt';
    }
    return '$count ${count == 1 ? 'entry' : 'entries'}';
  }
}

class FolderBackClipper extends CustomClipper<Path> {
  const FolderBackClipper({required this.tabHeight, required this.tabWidth});

  final double tabHeight;
  final double tabWidth;

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;
    final th = tabHeight;
    final tw = tabWidth;
    const radius = 16.0;

    path.moveTo(0, h - radius);
    path.quadraticBezierTo(0, h, radius, h);
    path.lineTo(w - radius, h);
    path.quadraticBezierTo(w, h, w, h - radius);

    path.lineTo(w, th + radius);
    path.quadraticBezierTo(w, th, w - radius, th);

    final tabEnd = tw + 16.0;
    path.lineTo(tabEnd, th);

    path.quadraticBezierTo(tw + 4.0, th, tw, th - 4.0);
    path.lineTo(tw - 10.0, 4.0);
    path.quadraticBezierTo(tw - 14.0, 0, tw - 20.0, 0);

    path.lineTo(radius, 0);
    path.quadraticBezierTo(0, 0, 0, radius);
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant FolderBackClipper oldClipper) =>
      oldClipper.tabHeight != tabHeight || oldClipper.tabWidth != tabWidth;
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.existing});

  final Category? existing;

  @override
  State<_CategoryEditorDialog> createState() => _CategoryEditorDialogState();
}

class _CategoryEditorDialogState extends State<_CategoryEditorDialog> {
  late final TextEditingController _nameController;
  late int _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existing?.name ?? '');
    _selectedColor =
        widget.existing?.color ?? _categoryColorOptions.first.toARGB32();
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
              ),
            );
          },
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
