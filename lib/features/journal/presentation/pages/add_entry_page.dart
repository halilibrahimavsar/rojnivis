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
import '../../../categories/data/models/category_model.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../quick_questions/presentation/quick_question_card.dart';
import '../../data/models/journal_entry_model.dart';
import '../bloc/journal_bloc.dart';
import '../widgets/audio_recorder_widget.dart';
import '../widgets/sketch_canvas.dart';
import '../../../../di/injection.dart';
import '../../data/repositories/entry_decoration_repository_singleton.dart';
import '../../domain/models/entry_sticker.dart';
import '../widgets/ai_writing_sheet.dart';
import '../widgets/sticker_layer.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../../../../core/services/ai_service.dart';

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
  late final String _workingEntryId;
  final StickerLayerController _stickerController = StickerLayerController();
  Timer? _stickerSaveDebounce;
  static const _compactDensity = VisualDensity(horizontal: -2, vertical: -2);

  @override
  void initState() {
    super.initState();
    _workingEntryId = widget.entryId ?? const Uuid().v4();
    _hydrateIfEditing();
    _loadStickers();
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
    _stickerSaveDebounce?.cancel();
    _stickerController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    final stickers = await entryDecorationRepository.getStickers(
      _workingEntryId,
    );
    if (!mounted) return;
    _stickerController.setStickers(stickers);
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

  void _removeTag(String tag) {
    final tags = _parseTags(_tagsController.text).toList();
    tags.remove(tag);
    setState(() {
      _tagsController.text = tags.join(', ');
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

    final entry = JournalEntryModel(
      id: _workingEntryId,
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
    final selection = await showModalBottomSheet<int>(
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
                    title: Text('happy'.tr()),
                    trailing:
                        _selectedMoodIndex == 0
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, 0),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sentiment_dissatisfied_outlined),
                    title: Text('sad'.tr()),
                    trailing:
                        _selectedMoodIndex == 1
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, 1),
                  ),
                  ListTile(
                    leading: const Icon(Icons.sentiment_neutral_outlined),
                    title: Text('neutral'.tr()),
                    trailing:
                        _selectedMoodIndex == 2
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, 2),
                  ),
                  ListTile(
                    leading: const Icon(Icons.celebration_outlined),
                    title: Text('excited'.tr()),
                    trailing:
                        _selectedMoodIndex == 3
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, 3),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.sentiment_very_dissatisfied_outlined,
                    ),
                    title: Text('angry'.tr()),
                    trailing:
                        _selectedMoodIndex == 4
                            ? const Icon(Icons.check)
                            : null,
                    onTap: () => Navigator.pop(context, 4),
                  ),
                ],
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
      await entryDecorationRepository.saveStickers(
        _workingEntryId,
        stickers ?? _stickerController.stickers,
      );
    });
  }

  Future<void> _persistStickersNow() async {
    _stickerSaveDebounce?.cancel();
    await entryDecorationRepository.saveStickers(
      _workingEntryId,
      _stickerController.stickers,
    );
  }

  IconData _moodIcon(int index) {
    switch (index) {
      case 0:
        return Icons.sentiment_very_satisfied_rounded;
      case 1:
        return Icons.sentiment_dissatisfied_rounded;
      case 3:
        return Icons.celebration_rounded;
      case 4:
        return Icons.sentiment_very_dissatisfied_rounded;
      default:
        return Icons.sentiment_neutral_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text(
              'save'.tr(),
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          // 1. Fullscreen Paper Background
          const Positioned.fill(
            child: ThemedBackdrop(
              opacity: 1,
              blurSigma: 0,
              vignette: true,
              applyPageStudio: true,
            ),
          ),

          // 2. Main Content Area
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                _buildHeaderSection(theme),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMetaSection(theme),
                        const SizedBox(height: 16),
                        _buildDailyPage(theme),
                        const SizedBox(height: 18),
                        _buildAttachmentsSection(theme),
                        const SizedBox(height: 140),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 3. Floating Modern Tool Tray
          Align(
            alignment: Alignment.bottomCenter,
            child: _buildModernToolTray(colorScheme),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderSection(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickDateTime,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(
                  alpha: 0.4,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(_selectedDate),
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              _moodIcon(_selectedMoodIndex),
              color: theme.colorScheme.secondary,
            ),
            onPressed: _openMoodPicker,
          ),
        ],
      ),
    );
  }

  Widget _buildMetaSection(ThemeData theme) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        final categories =
            state is CategoryLoaded
                ? state.categories
                : const <CategoryModel>[];
        CategoryModel? selectedCategory;
        if (_selectedCategoryId != null) {
          for (final category in categories) {
            if (category.id == _selectedCategoryId) {
              selectedCategory = category;
              break;
            }
          }
        }

        final tags = _parseTags(_tagsController.text);
        final colors = theme.colorScheme;
        final categoryColor =
            selectedCategory == null
                ? colors.outlineVariant
                : Color(selectedCategory.color);

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _metaChip(
              icon: Icons.category_outlined,
              label: selectedCategory?.name ?? 'no_category'.tr(),
              onTap: _openCategoryPicker,
              accent: categoryColor,
              theme: theme,
            ),
            if (tags.isEmpty)
              _metaChip(
                icon: Icons.add_rounded,
                label: 'tags_label'.tr(),
                onTap: _openTagsEditor,
                accent: colors.primary,
                theme: theme,
                isEmphasized: true,
              ),
            for (final tag in tags)
              InputChip(
                label: Text(tag),
                avatar: const Icon(Icons.tag_outlined, size: 18),
                onDeleted: () => _removeTag(tag),
                onPressed: _openTagsEditor,
                visualDensity: _compactDensity,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                backgroundColor: colors.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                side: BorderSide(
                  color: colors.outlineVariant.withValues(alpha: 0.6),
                ),
              ),
            if (tags.isNotEmpty)
              _metaChip(
                icon: Icons.add,
                label: 'tags_label'.tr(),
                onTap: _openTagsEditor,
                accent: colors.primary,
                theme: theme,
                isEmphasized: true,
              ),
          ],
        );
      },
    );
  }

  Widget _buildDailyPage(ThemeData theme) {
    final colors = theme.colorScheme;
    final localeCode = context.locale.languageCode;
    final titleHint =
        localeCode == 'tr'
            ? 'Bugunun sayfasina bir baslik ver...'
            : 'Give today\'s page a title...';
    final contentHint =
        localeCode == 'tr'
            ? 'Sevgili gunluk,\n\nBugun neler hissettigini, neler yasadigini ve aklinda kalan detaylari bu satirlara yaz...'
            : 'Dear diary,\n\nWrite what you felt today, what happened, and the small details you want to remember...';

    return ThemedPaper(
      lined: true,
      animated: true,
      applyPageStudio: true,
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.all(Radius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 560),
        child: Stack(
          children: [
            // Light page header tint for realistic paper variation.
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              height: 88,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.surface.withValues(alpha: 0.32),
                      colors.surface.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: StickerLayer(
                controller: _stickerController,
                editable: true,
                onChanged: _onStickerChanged,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
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
                        color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildWritingField(
                    controller: _titleController,
                    hint: titleHint,
                    isTitle: true,
                  ),
                  const SizedBox(height: 10),
                  Divider(
                    height: 1,
                    color: colors.outlineVariant.withValues(alpha: 0.45),
                  ),
                  const SizedBox(height: 10),
                  _buildWritingField(
                    controller: _contentController,
                    hint: contentHint,
                    isTitle: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWritingField({
    required TextEditingController controller,
    required String hint,
    required bool isTitle,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final inkColor = colors.onSurface.withValues(alpha: isTitle ? 0.92 : 0.9);

    final textStyle =
        isTitle
            ? GoogleFonts.caveat(
              textStyle: theme.textTheme.displaySmall?.copyWith(
                color: inkColor,
                fontSize: 42,
                height: 1.08,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.09),
                    blurRadius: 0.9,
                    offset: const Offset(0.3, 0.6),
                  ),
                ],
              ),
            )
            : GoogleFonts.patrickHand(
              textStyle: theme.textTheme.bodyLarge?.copyWith(
                color: inkColor,
                // Match ruled-paper step (~28px) so handwriting fits lines.
                fontSize: 20,
                height: 1.4,
                letterSpacing: 0.05,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 0.8,
                    offset: const Offset(0.3, 0.55),
                  ),
                ],
              ),
            );

    return TextField(
      controller: controller,
      style: textStyle,
      cursorColor: colors.primary.withValues(alpha: 0.85),
      decoration: InputDecoration(
        hintText: hint,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        disabledBorder: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedErrorBorder: InputBorder.none,
        isDense: true,
        filled: false,
        contentPadding: EdgeInsets.zero,
        hintStyle: textStyle.copyWith(
          color: inkColor.withValues(alpha: 0.34),
          shadows: const [],
        ),
      ),
      minLines: isTitle ? 1 : 18,
      maxLines: null,
    );
  }

  Widget _metaChip({
    required IconData icon,
    required String label,
    required ThemeData theme,
    required VoidCallback onTap,
    required Color accent,
    bool isEmphasized = false,
  }) {
    final colors = theme.colorScheme;
    final background = Color.alphaBlend(
      accent.withValues(alpha: isEmphasized ? 0.18 : 0.12),
      colors.surface,
    );

    return Tooltip(
      message: label,
      child: ActionChip(
        avatar: Icon(icon, size: 18, color: accent),
        label: Text(label),
        labelStyle: theme.textTheme.labelMedium?.copyWith(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        onPressed: onTap,
        visualDensity: _compactDensity,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        backgroundColor: background,
        side: BorderSide(color: accent.withValues(alpha: 0.4)),
      ),
    );
  }

  Widget _buildAttachmentsSection(ThemeData theme) {
    final colors = theme.colorScheme;
    final attachments = List.of(_attachmentPaths);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'attachments'.tr(),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            if (attachments.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attachments.length}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colors.primary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (attachments.isEmpty)
          Text(
            'no_attachments'.tr(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          )
        else
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: attachments.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final path = attachments[index];
                return _buildAttachmentTile(theme, path);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAttachmentTile(ThemeData theme, String path) {
    final colors = theme.colorScheme;
    final isImage = isImagePath(path);
    final previewBackground = colors.surfaceContainerHighest.withValues(
      alpha: 0.5,
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => openAttachment(context, path),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 140,
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colors.outlineVariant.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child:
                      isImage
                          ? Image.file(File(path), fit: BoxFit.cover)
                          : Container(
                            color: previewBackground,
                            child: Center(
                              child: Icon(
                                _attachmentIcon(path),
                                color: colors.primary,
                                size: 28,
                              ),
                            ),
                          ),
                ),
              ),
              Positioned(
                left: 8,
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _fileName(path),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Material(
                  color: colors.surface.withValues(alpha: 0.9),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => _removeAttachment(path),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.close_rounded,
                        size: 16,
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
