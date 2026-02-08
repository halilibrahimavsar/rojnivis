import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/app_card.dart';
import '../../data/models/category_model.dart';
import '../bloc/category_bloc.dart';

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
    BuildContext context, {
    CategoryModel? existing,
  }) async {
    final result = await showDialog<CategoryModel>(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('categories'.tr())),
      body: BlocBuilder<CategoryBloc, CategoryState>(
        builder: (context, state) {
          if (state is CategoryInitial || state is CategoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CategoryError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }

          final categories = (state as CategoryLoaded).categories;
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

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final c = categories[index];
              final color = Color(c.color);

              return Dismissible(
                key: ValueKey(c.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.error,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.onError,
                  ),
                ),
                confirmDismiss: (_) => _confirmDelete(context),
                onDismissed: (_) {
                  context.read<CategoryBloc>().add(
                    DeleteCategoryRequested(categoryId: c.id),
                  );
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('deleted'.tr())));
                },
                child: AppCard(
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(c.name),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'edit'.tr(),
                      onPressed: () => _openEditor(context, existing: c),
                    ),
                    onTap: () => _openEditor(context, existing: c),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add),
        label: Text('add_category'.tr()),
      ),
    );
  }
}

class _CategoryEditorDialog extends StatefulWidget {
  const _CategoryEditorDialog({this.existing});

  final CategoryModel? existing;

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
                                    ? Theme.of(
                                      context,
                                    ).colorScheme.onSurface
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
              CategoryModel(
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
