import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../../../../core/widgets/glass_overlays.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';
import '../../../categories/domain/entities/category.dart';
import '../../domain/entities/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/sketch_canvas.dart';
import '../../../../di/injection.dart';
import '../../domain/entities/entry_sticker.dart';
import '../../domain/usecases/get_stickers.dart';
import '../../domain/usecases/save_stickers.dart';
import '../widgets/ai_writing_sheet.dart';
import '../widgets/sticker_layer.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../../../../core/services/ai_service.dart';

class AddEntryPage extends StatefulWidget {
  const AddEntryPage({super.key, this.entryId, this.initialContent});
  final String? entryId;
  final String? initialContent;

  @override
  State<AddEntryPage> createState() => _AddEntryPageState();
}

class _AddEntryPageState extends State<AddEntryPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagsController = TextEditingController();
  final _titleFocusNode = FocusNode();
  final _contentFocusNode = FocusNode();

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryId;
  Mood _selectedMood = Mood.neutral;
  final List<String> _attachmentPaths = [];

  JournalEntry? _editingEntry;
  late final String _workingEntryId;
  final StickerLayerController _stickerController = StickerLayerController();
  Timer? _stickerSaveDebounce;

  @override
  void initState() {
    super.initState();
    _workingEntryId = widget.entryId ?? const Uuid().v4();
    _hydrateIfEditing();
    if (widget.initialContent != null && _contentController.text.isEmpty) {
      _contentController.text = widget.initialContent!;
    }
    _loadStickers();
  }

  void _hydrateIfEditing() {
    final entryId = widget.entryId;
    if (entryId == null) return;

    final state = context.read<JournalBloc>().state;
    if (state is! JournalLoaded) return;

    JournalEntry? entry;
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
    _selectedMood = entry.mood;
    _attachmentPaths
      ..clear()
      ..addAll(entry.attachmentPaths);
  }

  @override
  void dispose() {
    _stickerSaveDebounce?.cancel();
    _stickerController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    _titleFocusNode.dispose();
    _contentFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    final (failure, stickers) = await getIt<GetStickers>()(_workingEntryId);
    if (!mounted) return;
    if (failure == null && stickers != null) {
      _stickerController.setStickers(stickers);
    }
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

  void _removeAttachment(String path) {
    setState(() {
      _attachmentPaths.remove(path);
    });
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
                _contentController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _contentController.text.length),
                );
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
    await _persistStickersNow();
    if (!mounted) return;

    final entry = JournalEntry(
      id: _workingEntryId,
      title: _titleController.text.trim(),
      content: content,
      date: _selectedDate,
      mood: _selectedMood,
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

  Future<void> _openTagsEditor() async {
    var draft = _tagsController.text;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Padding(
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
              TextFormField(
                initialValue: draft,
                decoration: InputDecoration(
                  hintText: 'tags_hint'.tr(),
                  prefixIcon: const Icon(Icons.tag_outlined),
                ),
                autofocus: true,
                minLines: 1,
                maxLines: 3,
                onChanged: (value) => draft = value,
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
                      onPressed: () => Navigator.pop(context, draft),
                      child: Text('save'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

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
    final selection = await showModalBottomSheet<Mood>(
      context: context,
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.sentiment_very_satisfied_outlined,
                    ),
                    title: Text('mood_happy'.tr()),
                    trailing:
                        _selectedMood == Mood.happy
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, Mood.happy),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sentiment_dissatisfied_outlined),
                    title: Text('mood_sad'.tr()),
                    trailing:
                        _selectedMood == Mood.sad
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, Mood.sad),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sentiment_neutral_outlined),
                    title: Text('mood_neutral'.tr()),
                    trailing:
                        _selectedMood == Mood.neutral
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, Mood.neutral),
                  ),
                  ListTile(
                    leading: const Icon(Icons.celebration_outlined),
                    title: Text('mood_excited'.tr()),
                    trailing:
                        _selectedMood == Mood.excited
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, Mood.excited),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.sentiment_very_dissatisfied_outlined,
                    ),
                    title: Text('mood_angry'.tr()),
                    trailing:
                        _selectedMood == Mood.angry
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, Mood.angry),
                  ),
                ],
              ),
            ),
          ),
    );
    if (selection == null || !mounted) return;
    setState(() => _selectedMood = selection);
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
                  Text(
                    'voice_note'.tr(),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
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

  Future<void> _openQuickQuestions() async {
    await showModalBottomSheet<void>(
      context: context,
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

  Future<void> _openStickerPicker() async {
    final sticker = await showStickerPickerSheet(context);
    if (!mounted || sticker == null) return;
    _stickerController.addSticker(sticker.assetPath);
  }

  void _onStickerChanged(List<EntrySticker> stickers) {
    _scheduleStickerSave(stickers);
  }

  void _scheduleStickerSave([List<EntrySticker>? stickers]) {
    _stickerSaveDebounce?.cancel();
    _stickerSaveDebounce = Timer(const Duration(milliseconds: 300), () async {
      final s = stickers ?? _stickerController.stickers;
      await getIt<SaveStickers>()(_workingEntryId, s);
    });
  }

  Future<void> _persistStickersNow() async {
    _stickerSaveDebounce?.cancel();
    await getIt<SaveStickers>()(_workingEntryId, _stickerController.stickers);
  }

  IconData _moodIcon(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return Icons.sentiment_very_satisfied_rounded;
      case Mood.sad:
        return Icons.sentiment_dissatisfied_rounded;
      case Mood.excited:
        return Icons.celebration_rounded;
      case Mood.angry:
        return Icons.sentiment_very_dissatisfied_rounded;
      case Mood.neutral:
        return Icons.sentiment_neutral_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final localeCode = context.locale.languageCode;
    final titleHint =
        localeCode == 'tr'
            ? 'Bugünün sayfasına bir başlik ver...'
            : 'Give today\'s page a title...';
    final contentHint =
        localeCode == 'tr'
            ? 'Sevgili günlük,\n\nBugün neler hissettiğini, neler yaşadığını ve aklında kalan detayları bu satırlara yaz...'
            : 'Dear diary,\n\nWrite what you felt today, what happened, and the small details you want to remember...';

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      body: ThemedPaper(
        lined: true,
        animated: true,
        applyPageStudio: true,
        borderRadius: BorderRadius.zero,
        padding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Stickers layer on fullscreen paper
            Positioned.fill(
              child: StickerLayer(
                controller: _stickerController,
                editable: true,
                onChanged: _onStickerChanged,
              ),
            ),

            // Text input canvas
            Positioned.fill(
              child: GestureDetector(
                onTap: () => _contentFocusNode.requestFocus(),
                behavior: HitTestBehavior.translucent,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(28, 120, 28, 280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          DateFormat.yMMMMd(
                            context.locale.toString(),
                          ).format(_selectedDate),
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildWritingField(
                        controller: _titleController,
                        hint: titleHint,
                        isTitle: true,
                        focusNode: _titleFocusNode,
                      ),
                      const SizedBox(height: 10),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.45,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildWritingField(
                        controller: _contentController,
                        hint: contentHint,
                        isTitle: false,
                        focusNode: _contentFocusNode,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Top Header date & meta details
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: _buildFloatingTopHeader(theme),
            ),

            // Floating Attachments Preview slider
            _buildFloatingAttachmentsRow(theme),

            // Bottom action tray
            Align(
              alignment: Alignment.bottomCenter,
              child: _buildModernToolTray(colorScheme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingTopHeader(ThemeData theme) {
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          opacity: isDark ? 0.2 : 0.15,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
                style: IconButton.styleFrom(
                  backgroundColor: Colors.transparent,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildHeaderGlassPill(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat.yMMMd().format(_selectedDate),
                        onTap: _pickDateTime,
                        theme: theme,
                      ),
                      BlocBuilder<CategoryBloc, CategoryState>(
                        builder: (context, state) {
                          final categories =
                              state is CategoryLoaded
                                  ? state.categories
                                  : const [];
                          Category? selectedCategory;
                          if (_selectedCategoryId != null) {
                            for (final c in categories) {
                              if (c.id == _selectedCategoryId) {
                                selectedCategory = c;
                                break;
                              }
                            }
                          }
                          final categoryColor =
                              selectedCategory == null
                                  ? colors.outline
                                  : Color(selectedCategory.color);
                          return _buildHeaderGlassPill(
                            icon: Icons.category_outlined,
                            label: selectedCategory?.name ?? 'no_category'.tr(),
                            onTap: _openCategoryPicker,
                            theme: theme,
                            color: categoryColor,
                          );
                        },
                      ),
                      _buildHeaderGlassPill(
                        icon: _moodIcon(_selectedMood),
                        label: 'mood_${_selectedMood.name}'.tr(),
                        onTap: _openMoodPicker,
                        theme: theme,
                        color: colors.secondary,
                      ),
                      _buildHeaderGlassPill(
                        icon: Icons.tag_outlined,
                        label:
                            _parseTags(_tagsController.text).isEmpty
                                ? 'tags_label'.tr()
                                : '${_parseTags(_tagsController.text).length} ${'tags_label'.tr()}',
                        onTap: _openTagsEditor,
                        theme: theme,
                        color: colors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary.withValues(alpha: 0.85),
                  foregroundColor: colors.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'save'.tr(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderGlassPill({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ThemeData theme,
    Color? color,
  }) {
    final colors = theme.colorScheme;
    final pillColor = color ?? colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: pillColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: pillColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: pillColor),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: pillColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingAttachmentsRow(ThemeData theme) {
    if (_attachmentPaths.isEmpty) return const SizedBox.shrink();

    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 20,
      right: 20,
      bottom: 116,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        opacity: isDark ? 0.25 : 0.18,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Row(
                children: [
                  Icon(
                    Icons.attachment_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'attachments'.tr(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_attachmentPaths.length}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: _attachmentPaths.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final path = _attachmentPaths[index];
                  return _buildAttachmentTileSmall(theme, path);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentTileSmall(ThemeData theme, String path) {
    final colors = theme.colorScheme;
    final isImage = isImagePath(path);
    final previewBackground = colors.surfaceContainerHighest.withValues(
      alpha: 0.5,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openAttachment(context, path),
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          width: 110,
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.5),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child:
                      isImage
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                            color: previewBackground,
                            child: Center(
                              child: Icon(
                                _attachmentIcon(path),
                                color: colors.primary,
                                size: 20,
                              ),
                            ),
                          ),
                ),
              ),
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _fileName(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 4,
                child: Material(
                  color: colors.surface.withValues(alpha: 0.85),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _removeAttachment(path),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Icon(
                        Icons.close_rounded,
                        size: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernToolTray(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(20),
      height: 86,
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: [
              _trayAction(
                icon: Icons.image_outlined,
                label: 'add_photo'.tr(),
                onTap: _pickImage,
              ),
              _trayAction(
                icon: Icons.attach_file_outlined,
                label: 'add_file'.tr(),
                onTap: _pickFile,
              ),
              _trayAction(
                icon: Icons.mic_none_rounded,
                label: 'voice_note'.tr(),
                onTap: _openAudioRecorder,
              ),
              _trayAction(
                icon: Icons.draw_outlined,
                label: 'sketch'.tr(),
                onTap: _openSketchCanvas,
              ),
              _trayAction(
                icon: Icons.style_outlined,
                label: 'tags_label'.tr(),
                onTap: _openTagsEditor,
              ),
              _trayAction(
                icon: Icons.emoji_emotions_outlined,
                label: 'stickers'.tr(),
                onTap: _openStickerPicker,
              ),
              _trayAction(
                icon: Icons.auto_awesome_rounded,
                label: 'continue_writing'.tr(),
                onTap: _aiContinueWriting,
                isSpecial: true,
              ),
              _trayAction(
                icon: Icons.auto_awesome_outlined,
                label: 'generate_tags'.tr(),
                onTap: _aiGenerateTags,
              ),
              _trayAction(
                icon: Icons.help_outline_rounded,
                label: 'quick_question'.tr(),
                onTap: _openQuickQuestions,
              ),
              const VerticalDivider(indent: 16, endIndent: 16),
              _trayAction(
                icon: Icons.more_horiz_rounded,
                label: 'category'.tr(),
                onTap: _openCategoryPicker,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _trayAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isSpecial = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final accent = isSpecial ? colors.primary : colors.onSurfaceVariant;
    final background =
        isSpecial
            ? Color.alphaBlend(
              colors.primary.withValues(alpha: 0.18),
              colors.surface,
            )
            : colors.surfaceContainerHighest.withValues(alpha: 0.6);
    final borderColor =
        isSpecial
            ? colors.primary.withValues(alpha: 0.4)
            : colors.outlineVariant.withValues(alpha: 0.5);

    return Tooltip(
      message: label,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              width: 88,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: accent),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                      height: 1.15,
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

  Widget _buildWritingField({
    required TextEditingController controller,
    required String hint,
    required bool isTitle,
    required FocusNode focusNode,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textStyle =
        isTitle
            ? theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.grey.shade200 : const Color(0xFF5D4037),
            )
            : TextStyle(
              fontFamily: GoogleFonts.patrickHand().fontFamily,
              fontSize: 20,
              height: 1.5,
              color: isDark ? Colors.grey.shade300 : const Color(0xFF4E342E),
            );

    return TextField(
      controller: controller,
      focusNode: focusNode,
      maxLines: isTitle ? 1 : null,
      keyboardType: isTitle ? TextInputType.text : TextInputType.multiline,
      style: textStyle,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: textStyle?.copyWith(
          color: (isDark ? Colors.grey.shade600 : const Color(0xFF8D6E63))
              .withValues(alpha: 0.6),
        ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}

/// Custom Painter to create the "Lined Journal" look
class JournalPaperPainter extends CustomPainter {
  final Color lineColor;
  final Color marginColor;

  JournalPaperPainter({required this.lineColor, required this.marginColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paintLine =
        Paint()
          ..color = lineColor
          ..strokeWidth = 1.0;

    final paintMargin =
        Paint()
          ..color = marginColor
          ..strokeWidth = 2.0;

    // Draw horizontal lines
    double gap = 30.0;
    for (double i = gap * 4; i < size.height; i += gap) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paintLine);
    }

    // Draw vertical margin line
    canvas.drawLine(const Offset(45, 0), Offset(45, size.height), paintMargin);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
