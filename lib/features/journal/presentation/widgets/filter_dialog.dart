import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../domain/models/filter_model.dart';

class FilterDialog extends StatefulWidget {
  const FilterDialog({super.key, required this.initialFilter});

  final JournalFilter initialFilter;

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late List<String> _selectedCategories;
  late TextEditingController _tagsController;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialFilter.startDate;
    _endDate = widget.initialFilter.endDate;
    _selectedCategories = List.from(widget.initialFilter.categoryIds ?? []);
    _tagsController = TextEditingController(
      text: widget.initialFilter.tags?.join(', ') ?? '',
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('filter_entries'.tr()),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('date_range'.tr(), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _startDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _startDate != null
                          ? DateFormat.yMMMd().format(_startDate!)
                          : 'start_date'.tr(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setState(() => _endDate = picked);
                      }
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: Text(
                      _endDate != null
                          ? DateFormat.yMMMd().format(_endDate!)
                          : 'end_date'.tr(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('categories'.tr(), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: state.categories.map((category) {
                      final isSelected = _selectedCategories.contains(category.id);
                      final color = Color(category.color);
                      return FilterChip(
                        label: Text(category.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _selectedCategories.add(category.id);
                            } else {
                              _selectedCategories.remove(category.id);
                            }
                          });
                        },
                        checkmarkColor: isSelected ? Colors.white : null,
                        backgroundColor: color.withOpacity(0.1),
                        selectedColor: color,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      );
                    }).toList(),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),
            Text('tags'.tr(), style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 8),
            TextField(
              controller: _tagsController,
              decoration: InputDecoration(
                hintText: 'tags_hint'.tr(), // "tag1, tag2"
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            // Reset filters
            setState(() {
              _startDate = null;
              _endDate = null;
              _selectedCategories.clear();
              _tagsController.clear();
            });
          },
          child: Text('reset'.tr()),
        ),
        FilledButton(
          onPressed: () {
            final tags = _tagsController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

            final filter = widget.initialFilter.copyWith(
              startDate: _startDate,
              endDate: _endDate,
              categoryIds: _selectedCategories,
              tags: tags,
            );
            Navigator.of(context).pop(filter);
          },
          child: Text('apply'.tr()),
        ),
      ],
    );
  }
}
