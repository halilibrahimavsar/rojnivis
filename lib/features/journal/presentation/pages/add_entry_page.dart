import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/attachment_backdrop.dart';
import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';
import '../../data/models/journal_entry_model.dart';
import '../bloc/journal_bloc.dart';
import '../widgets/audio_recorder_widget.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../widgets/sketch_canvas.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;
import '../../../../di/injection.dart';
import '../../../journal/presentation/widgets/ai_writing_sheet.dart';
import '../../../../core/services/ai_service.dart';

const _compactDensity = VisualDensity(horizontal: -2, vertical: -2);

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key, this.entryId});

  final String? entryId;

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  int _selectedMoodIndex = 2;
  final List<String> _attachmentPaths = [];

  JournalEntryModel? _editingEntry;

  @override
  void initState() {
    super.initState();
    _hydrateIfEditing();
  }

  void _hydrateIfEditing() {
    final entryId = widget.entryId;
    if (entryId == null) return;

    final state = context.read<JournalBloc>().state;
    if (state is! JournalLoaded) return;

    JournalEntryModel? entry;
    for (final e in state.entries) {
      if (e.id == entryId) {
        entry = e;
        break;
      }
    }
    if (entry == null) return;

    _editingEntry = entry;
    _titleController.text = entry.title;
    _contentController.text = entry.content;
    _tagsController.text = entry.tags.join(', ');
    _selectedDate = entry.date;
    _selectedCategoryId = entry.categoryId;
    _selectedMoodIndex = entry.moodIndex;
    _attachmentPaths
      ..clear()
      ..addAll(entry.attachmentPaths);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final initialDate = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null) return;
    if (!mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );

    if (!mounted) return;
    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime?.hour ?? _selectedDate.hour,
        pickedTime?.minute ?? _selectedDate.minute,
      );
    });
  }

  void _insertQuickQuestion(String question) {
    final text = _contentController.text;
    final prefix = text.trim().isEmpty ? '' : '\n\n';
    _contentController.text = '$text$prefix$question\n';
    _contentController.selection = TextSelection.fromPosition(
      TextPosition(offset: _contentController.text.length),
    );
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList(growable: false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      if (!_attachmentPaths.contains(image.path)) {
        _attachmentPaths.add(image.path);
      }
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() {
      if (!_attachmentPaths.contains(path)) {
        _attachmentPaths.add(path);
      }
    });
  }

  IconData _attachmentIcon(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.m4a') ||
        lower.endsWith('.aac') ||
        lower.endsWith('.mp3')) {
      return Icons.mic_none_outlined;
    }
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg')) {
      return Icons.image_outlined;
    }
    return Icons.attach_file_outlined;
  }

  Future<void> _openSketchCanvas() async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => SketchCanvas(
              onCancel: () => Navigator.pop(context),
              onSave: (ui.Image image) async {
                final bytes = await image.toByteData(
                  format: ui.ImageByteFormat.png,
                );
                if (bytes == null) return;

                final directory = await getApplicationDocumentsDirectory();
                final fileName = 'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
                final file = File('${directory.path}/$fileName');
                await file.writeAsBytes(bytes.buffer.asUint8List());

                if (mounted) {
                  setState(() {
                    _attachmentPaths.add(file.path);
                  });
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
      ),
    );
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  Future<void> _aiContinueWriting() async {
    final aiService = getIt<AiService>();
    if (!aiService.isConfigured) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ai_not_configured'.tr())),
      );
      return;
    }

    final currentText = _contentController.text;
    if (currentText.trim().isEmpty) return;
    
    final suggestionFuture = aiService.continueWriting(currentText);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiWritingSheet(
        suggestionFuture: suggestionFuture,
        onAccept: (suggestion) {
          setState(() {
            _contentController.text = '$currentText $suggestion';
          });
        },
      ),
    );
  }

  Future<void> _aiGenerateTags() async {
    final aiService = getIt<AiService>();
    if (!aiService.isConfigured) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ai_not_configured'.tr())),
      );
      return;
    }

    final currentText = _contentController.text;
    if (currentText.trim().length < 20) return;

    final tags = await aiService.generateTags(currentText);
    if (tags.isNotEmpty && mounted) {
      setState(() {
        final existingTags = _parseTags(_tagsController.text).toSet();
        existingTags.addAll(tags);
        _tagsController.text = existingTags.join(', ');
      });
    }
  }

  Future<void> _save() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('content_required'.tr())));
      return;
    }

    String? summary = _editingEntry?.summary;
    final aiService = getIt<AiService>();
    
    // Auto-generate summary if long enough and not present
    if (aiService.isConfigured && (summary == null || summary.isEmpty) && content.length > 100) {
      try {
        summary = await aiService.summarize(content);
      } catch (_) {
        // Silently fail summary generation
      }
    }

    if (!mounted) return;

    final entry = JournalEntryModel(
      id: _editingEntry?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      content: content,
      date: _selectedDate,
      moodIndex: _selectedMoodIndex,
      categoryId: _selectedCategoryId,
      tags: _parseTags(_tagsController.text),
      attachmentPaths: List.of(_attachmentPaths),
      summary: summary,
    );

    context.read<JournalBloc>().add(UpsertEntryRequested(entry: entry));
    
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('saved'.tr())));
  }

  @override
  Widget build(BuildContext context) {
    final showAttachmentBackdrop = context.select<SettingsBloc, bool>((bloc) {
      final state = bloc.state;
      if (state is SettingsLoaded) return state.showAttachmentBackdrop;
      return AppDefaults.defaultAttachmentBackdrop;
    });

    final isEditing = _editingEntry != null;
    final locale = context.locale.toString();
    final formattedDate = DateFormat.yMMMMEEEEd(
      locale,
    ).add_Hm().format(_selectedDate);
    final labelStyle = Theme.of(context).textTheme.labelLarge?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
    );
    final miniButtonPadding = const EdgeInsets.symmetric(
      horizontal: 12,
      vertical: 8,
    );

    ButtonStyle miniButtonStyle({Color? background, Color? foreground}) {
      return ButtonStyle(
        visualDensity: _compactDensity,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const WidgetStatePropertyAll(Size(0, 0)),
        padding: WidgetStatePropertyAll(miniButtonPadding),
        backgroundColor:
            background == null ? null : WidgetStatePropertyAll(background),
        foregroundColor:
            foreground == null ? null : WidgetStatePropertyAll(foreground),
      );
    }

    String? backdropPath;
    if (showAttachmentBackdrop) {
      for (final path in _attachmentPaths) {
        if (isImagePath(path)) {
          backdropPath = path;
          break;
        }
      }
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        title: Text(isEditing ? 'edit_entry'.tr() : 'create_entry'.tr()),
      ),
      body: Stack(
        children: [
          const Positioned.fill(
            child: ThemedBackdrop(blurSigma: 6, opacity: 0.95),
          ),
          if (backdropPath != null) AttachmentBackdrop(path: backdropPath),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
              children: [
                QuickQuestionCard(onUseQuestion: _insertQuickQuestion),
                const SizedBox(height: 12),
                ThemedPaper(
                  lined: true,
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('title'.tr(), style: labelStyle),
                      TextField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        textInputAction: TextInputAction.next,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Text('content'.tr(), style: labelStyle),
                          const Spacer(),
                          TextButton.icon(
                            onPressed: _aiContinueWriting,
                            icon: const Icon(Icons.auto_awesome, size: 14),
                            label: Text('Summarize / Continue'.tr(), style: const TextStyle(fontSize: 12)),
                            style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _contentController,
                        minLines: 6,
                        maxLines: 16,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _pickDateTime,
                        icon: const Icon(Icons.calendar_month_outlined),
                        label: Text(formattedDate),
                        style: OutlinedButton.styleFrom(
                          padding: miniButtonPadding,
                          visualDensity: _compactDensity,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          minimumSize: const Size(0, 0),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                BlocBuilder<CategoryBloc, CategoryState>(
                  builder: (context, state) {
                    final items = <DropdownMenuItem<String?>>[
                      DropdownMenuItem(
                        value: null,
                        child: Text('no_category'.tr()),
                      ),
                    ];

                    if (state is CategoryLoaded) {
                      items.addAll(
                        state.categories.map(
                          (c) =>
                              DropdownMenuItem(value: c.id, child: Text(c.name)),
                        ),
                      );
                    }

                    return DropdownButtonFormField<String?>(
                      value: _selectedCategoryId,
                      items: items,
                      onChanged:
                          (value) => setState(() {
                            _selectedCategoryId = value;
                          }),
                      decoration: InputDecoration(
                        labelText: 'category'.tr(),
                        prefixIcon: const Icon(Icons.category_outlined),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _MoodPicker(
                  value: _selectedMoodIndex,
                  onChanged:
                      (value) => setState(() => _selectedMoodIndex = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _tagsController,
                  decoration: InputDecoration(
                    labelText: 'tags_label'.tr(),
                    hintText: 'tags_hint'.tr(),
                    prefixIcon: const Icon(Icons.tag_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.auto_awesome, size: 18),
                      onPressed: _aiGenerateTags,
                      tooltip: 'generate_tags'.tr(),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'attachments'.tr(),
                    prefixIcon: const Icon(Icons.attach_file_outlined),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_attachmentPaths.isEmpty)
                        Text(
                          'no_attachments'.tr(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        )
                      else
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final maxLabelWidth = (constraints.maxWidth - 110)
                                .clamp(120.0, constraints.maxWidth);
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final path in _attachmentPaths)
                                  Tooltip(
                                    message: _fileName(path),
                                    child: InputChip(
                                      label: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          maxWidth: maxLabelWidth,
                                        ),
                                        child: Text(
                                          _fileName(path),
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      avatar: Icon(
                                        _attachmentIcon(path),
                                        size: 18,
                                      ),
                                      onDeleted:
                                          () => setState(
                                            () => _attachmentPaths.remove(path),
                                          ),
                                      onPressed:
                                          () => openAttachment(context, path),
                                      visualDensity: _compactDensity,
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                      labelPadding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                            onPressed: _pickImage,
                            icon: const Icon(Icons.image_outlined),
                            label: Text('add_photo'.tr()),
                            style: miniButtonStyle(
                              background:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              foreground:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          FilledButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file_outlined),
                            label: Text('add_file'.tr()),
                            style: miniButtonStyle(
                              background:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              foreground:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                          AudioRecorderWidget(
                            onRecordingComplete: (path) {
                              setState(() {
                                if (!_attachmentPaths.contains(path)) {
                                  _attachmentPaths.add(path);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _openSketchCanvas,
                            icon: const Icon(Icons.gesture_outlined),
                            label: const Text('Sketch'),
                            style: miniButtonStyle(
                              background:
                                  Theme.of(
                                    context,
                                  ).colorScheme.secondaryContainer,
                              foreground:
                                  Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.check),
            label: Text('save'.tr()),
            style: miniButtonStyle(),
          ),
        ),
      ),
    );
  }
}

class _MoodPicker extends StatelessWidget {
  const _MoodPicker({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final moods = <({int index, String key, IconData icon})>[
      (index: 0, key: 'happy', icon: Icons.sentiment_very_satisfied_outlined),
      (index: 2, key: 'neutral', icon: Icons.sentiment_neutral_outlined),
      (index: 1, key: 'sad', icon: Icons.sentiment_dissatisfied_outlined),
      (
        index: 4,
        key: 'angry',
        icon: Icons.sentiment_very_dissatisfied_outlined,
      ),
      (index: 3, key: 'excited', icon: Icons.celebration_outlined),
    ];

    return InputDecorator(
      decoration: InputDecoration(
        labelText: 'mood_label'.tr(),
        prefixIcon: const Icon(Icons.mood_outlined),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final mood in moods)
            ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(mood.icon, size: 16),
                  const SizedBox(width: 6),
                  Text('mood_${mood.key}'.tr()),
                ],
              ),
              selected: value == mood.index,
              visualDensity: _compactDensity,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              onSelected: (_) => onChanged(mood.index),
            ),
        ],
      ),
    );
  }
}
