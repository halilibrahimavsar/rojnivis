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
                final fileName =
                    'sketch_${DateTime.now().millisecondsSinceEpoch}.png';
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

  String _moodKey(int index) {
    switch (index) {
      case 0:
        return 'happy';
      case 1:
        return 'sad';
      case 2:
        return 'neutral';
      case 3:
        return 'excited';
      case 4:
        return 'angry';
      default:
        return 'neutral';
    }
  }

  String _selectedCategoryLabel(CategoryState state) {
    if (_selectedCategoryId == null) {
      return 'no_category'.tr();
    }
    if (state is CategoryLoaded) {
      for (final category in state.categories) {
        if (category.id == _selectedCategoryId) {
          return category.name;
        }
      }
    }
    return 'category'.tr();
  }

  Future<void> _openQuickQuestions() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: QuickQuestionCard(
                onUseQuestion: (question) {
                  Navigator.pop(context);
                  _insertQuickQuestion(question);
                },
              ),
            ),
          ),
    );
  }

  Future<void> _openTagsEditor() async {
    final controller = TextEditingController(text: _tagsController.text);
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder:
          (context) => Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'tags_label'.tr(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: 'tags_hint'.tr(),
                    prefixIcon: const Icon(Icons.tag_outlined),
                  ),
                  autofocus: true,
                  minLines: 1,
                  maxLines: 3,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('cancel'.tr()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton(
                        onPressed:
                            () => Navigator.pop(context, controller.text),
                        child: Text('save'.tr()),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    setState(() => _tagsController.text = result);
  }

  Future<void> _openCategoryPicker() async {
    const noCategoryValue = '__none__';
    final selection = await showModalBottomSheet<String>(
      context: context,
      builder:
          (context) => SafeArea(
            child: BlocBuilder<CategoryBloc, CategoryState>(
              builder: (context, state) {
                final categories =
                    state is CategoryLoaded ? state.categories : const [];
                return ListView(
                  shrinkWrap: true,
                  children: [
                    ListTile(
                      leading: const Icon(Icons.category_outlined),
                      title: Text('no_category'.tr()),
                      trailing:
                          _selectedCategoryId == null
                              ? const Icon(Icons.check)
                              : null,
                      onTap: () => Navigator.pop(context, noCategoryValue),
                    ),
                    for (final category in categories)
                      ListTile(
                        leading: const Icon(Icons.circle, size: 12),
                        title: Text(category.name),
                        trailing:
                            _selectedCategoryId == category.id
                                ? const Icon(Icons.check)
                                : null,
                        onTap: () => Navigator.pop(context, category.id),
                      ),
                  ],
                );
              },
            ),
          ),
    );
    if (!mounted || selection == null) return;
    setState(() {
      _selectedCategoryId = selection == noCategoryValue ? null : selection;
    });
  }

  Future<void> _openMoodPicker() async {
    final selection = await showModalBottomSheet<int>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: _MoodPicker(
                value: _selectedMoodIndex,
                onChanged: (value) => Navigator.pop(context, value),
              ),
            ),
          ),
    );
    if (selection == null || !mounted) return;
    setState(() => _selectedMoodIndex = selection);
  }

  Future<void> _openAudioRecorder() async {
    await showModalBottomSheet<void>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Voice', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  AudioRecorderWidget(
                    onRecordingComplete: (path) {
                      if (!mounted) return;
                      setState(() {
                        if (!_attachmentPaths.contains(path)) {
                          _attachmentPaths.add(path);
                        }
                      });
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Future<void> _aiContinueWriting() async {
    final aiService = getIt<AiService>();
    if (!aiService.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ai_not_configured'.tr())));
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
      builder:
          (context) => AiWritingSheet(
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ai_not_configured'.tr())));
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
    if (aiService.isConfigured &&
        (summary == null || summary.isEmpty) &&
        content.length > 100) {
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

  ButtonStyle _miniButtonStyle({Color? background, Color? foreground}) {
    return ButtonStyle(
      visualDensity: _compactDensity,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      minimumSize: const WidgetStatePropertyAll(Size(0, 0)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      backgroundColor:
          background == null ? null : WidgetStatePropertyAll(background),
      foregroundColor:
          foreground == null ? null : WidgetStatePropertyAll(foreground),
    );
  }

  Widget _buildMiniToolButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isPrimary = false,
    bool isActive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final background =
        isPrimary
            ? colorScheme.primary
            : (isActive
                ? colorScheme.secondaryContainer
                : colorScheme.surfaceContainerHighest);
    final foreground =
        isPrimary
            ? colorScheme.onPrimary
            : (isActive
                ? colorScheme.onSecondaryContainer
                : colorScheme.onSurface);

    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: _miniButtonStyle(background: background, foreground: foreground),
    );
  }

  Widget _buildAttachmentStrip() {
    if (_attachmentPaths.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _attachmentPaths.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final path = _attachmentPaths[index];
          return Tooltip(
            message: _fileName(path),
            child: InputChip(
              label: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 180),
                child: Text(
                  _fileName(path),
                  softWrap: false,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              avatar: Icon(_attachmentIcon(path), size: 18),
              onDeleted: () => setState(() => _attachmentPaths.remove(path)),
              onPressed: () => openAttachment(context, path),
              visualDensity: _compactDensity,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
          );
        },
      ),
    );
  }

  Widget _buildToolTray({
    required String formattedDate,
    required String categoryLabel,
    required String moodLabel,
    required String tagsLabel,
    required bool hasTags,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedPadding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.18),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_attachmentPaths.isNotEmpty) ...[
                _buildAttachmentStrip(),
                const SizedBox(height: 10),
              ],
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildMiniToolButton(
                    icon: Icons.calendar_month_outlined,
                    label: formattedDate,
                    onPressed: _pickDateTime,
                    isActive: true,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.category_outlined,
                    label: categoryLabel,
                    onPressed: _openCategoryPicker,
                    isActive: _selectedCategoryId != null,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.mood_outlined,
                    label: moodLabel,
                    onPressed: _openMoodPicker,
                    isActive: true,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.tag_outlined,
                    label: tagsLabel,
                    onPressed: _openTagsEditor,
                    isActive: hasTags,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.question_answer_outlined,
                    label: 'quick_question'.tr(),
                    onPressed: _openQuickQuestions,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.auto_awesome,
                    label: 'ai_assistant'.tr(),
                    onPressed: _aiContinueWriting,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.auto_awesome_outlined,
                    label: 'generate_tags'.tr(),
                    onPressed: _aiGenerateTags,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.image_outlined,
                    label: 'add_photo'.tr(),
                    onPressed: _pickImage,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.attach_file_outlined,
                    label: 'add_file'.tr(),
                    onPressed: _pickFile,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.mic_none_outlined,
                    label: 'Voice',
                    onPressed: _openAudioRecorder,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.gesture_outlined,
                    label: 'Sketch',
                    onPressed: _openSketchCanvas,
                  ),
                  _buildMiniToolButton(
                    icon: Icons.check,
                    label: 'save'.tr(),
                    onPressed: _save,
                    isPrimary: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
    final formattedDate = DateFormat.yMMMd(
      locale,
    ).add_Hm().format(_selectedDate);
    final categoryState = context.watch<CategoryBloc>().state;
    final categoryLabel = _selectedCategoryLabel(categoryState);
    final moodLabel = 'mood_${_moodKey(_selectedMoodIndex)}'.tr();
    final tags = _parseTags(_tagsController.text);
    final tagsLabel =
        tags.isEmpty
            ? 'tags_label'.tr()
            : '${tags.length} ${'tags_label'.tr()}';

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
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                children: [
                  Expanded(
                    child: ThemedPaper(
                      lined: true,
                      padding: EdgeInsets.zero,
                      child: Stack(
                        children: [
                          const Positioned.fill(child: _BookSpineOverlay()),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: _titleController,
                                  decoration: InputDecoration(
                                    hintText: 'title'.tr(),
                                    border: InputBorder.none,
                                    isDense: true,
                                    filled: false,
                                  ),
                                  textInputAction: TextInputAction.next,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                  onSubmitted:
                                      (_) => FocusScope.of(context).nextFocus(),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: TextField(
                                    controller: _contentController,
                                    expands: true,
                                    maxLines: null,
                                    minLines: null,
                                    decoration: InputDecoration(
                                      hintText: 'content'.tr(),
                                      border: InputBorder.none,
                                      isDense: true,
                                      filled: false,
                                    ),
                                    style:
                                        Theme.of(context).textTheme.bodyLarge,
                                  ),
                                ),
                              ],
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
        ],
      ),
      bottomNavigationBar: _buildToolTray(
        formattedDate: formattedDate,
        categoryLabel: categoryLabel,
        moodLabel: moodLabel,
        tagsLabel: tagsLabel,
        hasTags: tags.isNotEmpty,
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

class _BookSpineOverlay extends StatelessWidget {
  const _BookSpineOverlay();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final edge =
        isDark
            ? Colors.black.withValues(alpha: 0.18)
            : Colors.black.withValues(alpha: 0.08);
    final spine =
        isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.05);

    return IgnorePointer(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              edge,
              Colors.transparent,
              Colors.transparent,
              spine,
              Colors.transparent,
              Colors.transparent,
              edge,
            ],
            stops: const [0.0, 0.1, 0.48, 0.5, 0.52, 0.9, 1.0],
          ),
        ),
      ),
    );
  }
}
