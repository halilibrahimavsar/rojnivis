import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:uuid/uuid.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/domain/entities/category.dart';
import '../widgets/audio_recorder_widget.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key});

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  Mood _selectedMood = Mood.neutral;
  String? _selectedCategoryId;
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final List<String> _attachmentPaths = [];

  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [const Color(0xFF6C5CE7), const Color(0xFF00CEC9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('create_entry'.tr()),
        actions: [
          IconButton(icon: const Icon(Icons.check), onPressed: _saveEntry),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Picker
            InkWell(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.calendar_today, size: 20),
                    const SizedBox(width: 8),
                    Text(DateFormat.yMMMd().format(_selectedDate)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Mood Selector
            Text(
              'mood_label'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children:
                    Mood.values.map((mood) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Icon(_getMoodIcon(mood)),
                          selected: _selectedMood == mood,
                          onSelected: (selected) {
                            if (selected) setState(() => _selectedMood = mood);
                          },
                        ),
                      );
                    }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Category Selector
            Text(
              'categories'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                if (state is CategoryLoaded) {
                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text('Select Category'),
                    items:
                        state.categories.map((Category category) {
                          return DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          );
                        }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedCategoryId = value);
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            const SizedBox(height: 16),

            // Title
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
                filled: true,
              ),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Content
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Content',
                border: OutlineInputBorder(),
                filled: true,
                alignLabelWithHint: true,
              ),
              maxLines: 10,
              minLines: 5,
            ),
            const SizedBox(height: 16),

            // Attachments
            Text('Attachments', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._attachmentPaths.map(
                  (path) => Chip(
                    avatar: Icon(_getAttachmentIcon(path), size: 16),
                    label: Text(
                      path.split('/').last,
                      style: const TextStyle(fontSize: 12),
                    ),
                    onDeleted:
                        () => setState(() => _attachmentPaths.remove(path)),
                  ),
                ),
                ActionChip(
                  avatar: const Icon(Icons.image, size: 16),
                  label: const Text('Image'),
                  onPressed: _pickImage,
                ),
                ActionChip(
                  avatar: const Icon(Icons.attach_file, size: 16),
                  label: const Text('File'),
                  onPressed: _pickFile,
                ),
                AudioRecorderWidget(
                  onRecordingComplete: (path) {
                    setState(() => _attachmentPaths.add(path));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Tags
            Text(
              'tags_label'.tr(),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Wrap(
              spacing: 8,
              children:
                  _tags
                      .map(
                        (tag) => Chip(
                          label: Text(tag),
                          onDeleted: () => setState(() => _tags.remove(tag)),
                        ),
                      )
                      .toList(),
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _tagController,
                    decoration: const InputDecoration(hintText: 'Add Tag'),
                    onSubmitted: (value) {
                      if (value.isNotEmpty) {
                        setState(() {
                          _tags.add(value);
                          _tagController.clear();
                        });
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    if (_tagController.text.isNotEmpty) {
                      setState(() {
                        _tags.add(_tagController.text);
                        _tagController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  IconData _getAttachmentIcon(String path) {
    if (path.endsWith('.jpg') ||
        path.endsWith('.png') ||
        path.endsWith('.jpeg')) {
      return Icons.image;
    } else if (path.endsWith('.m4a') || path.endsWith('.mp3')) {
      return Icons.audiotrack;
    } else {
      return Icons.insert_drive_file;
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _attachmentPaths.add(image.path));
    }
  }

  Future<void> _pickFile() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() => _attachmentPaths.add(result.files.single.path!));
    }
  }

  IconData _getMoodIcon(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Icons.sentiment_very_satisfied;
      case Mood.sad:
        return Icons.sentiment_very_dissatisfied;
      case Mood.neutral:
        return Icons.sentiment_neutral;
      case Mood.excited:
        return Icons.sentiment_satisfied_alt;
      case Mood.angry:
        return Icons.mood_bad;
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveEntry() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title cannot be empty')));
      return;
    }

    final entry = JournalEntry(
      id: const Uuid().v4(),
      title: _titleController.text,
      content: _contentController.text,
      date: _selectedDate,
      mood: _selectedMood,
      tags: _tags,
      categoryId: _selectedCategoryId,
      attachmentPaths: _attachmentPaths,
    );

    context.read<JournalBloc>().add(AddJournalEntryEvent(entry));
    context.pop();
  }
}
