import 'dart:async';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/attachment_backdrop.dart';
import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../../../../core/widgets/glass_overlays.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/entry_sticker.dart';
import '../../domain/usecases/get_stickers.dart';
import '../../domain/usecases/save_stickers.dart';
import '../bloc/journal_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';
import '../widgets/ai_summary_card.dart';
import '../widgets/sticker_layer.dart';
import '../widgets/sticker_picker_sheet.dart';
import '../../../../core/services/ai_service.dart';
import '../../../../di/injection.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';
import '../../../categories/domain/entities/category.dart';

enum _EntryViewStyle { normal, letter, library }

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({super.key, required this.entryId});

  final String entryId;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  _EntryViewStyle _style = _EntryViewStyle.letter;
  bool _isSummarizing = false;
  bool _isStickerEditMode = false;
  final StickerLayerController _stickerController = StickerLayerController();
  Timer? _stickerSaveDebounce;

  @override
  void initState() {
    super.initState();
    _loadStickers();
  }

  @override
  void dispose() {
    _stickerSaveDebounce?.cancel();
    _stickerController.dispose();
    super.dispose();
  }

  Future<void> _loadStickers() async {
    final (failure, stickers) = await getIt<GetStickers>()(widget.entryId);
    if (!mounted) return;
    if (failure == null && stickers != null) {
      _stickerController.setStickers(stickers);
    }
  }

  Future<void> _openStickerPicker() async {
    final sticker = await showStickerPickerSheet(context);
    if (!mounted || sticker == null) return;
    _stickerController.addSticker(sticker.assetPath);
  }

  void _onStickersChanged(List<EntrySticker> stickers) {
    _stickerSaveDebounce?.cancel();
    _stickerSaveDebounce = Timer(const Duration(milliseconds: 300), () async {
      await getIt<SaveStickers>()(widget.entryId, stickers);
    });
  }

  Future<void> _summarizeEntry(JournalEntry entry) async {
    final aiService = getIt<AiService>();
    if (!aiService.isConfigured) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ai_not_configured'.tr())));
      return;
    }

    setState(() => _isSummarizing = true);
    try {
      final summary = await aiService.summarize(entry.content);
      if (mounted) {
        context.read<JournalBloc>().add(
          UpsertEntryRequested(entry: entry.copyWith(summary: summary)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate summary: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSummarizing = false);
    }
  }

  Future<void> _confirmDelete(JournalEntry entry) async {
    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('delete_entry'.tr()),
                content: Text('delete_entry_confirm'.tr()),
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

    if (!shouldDelete || !mounted) return;
    context.read<JournalBloc>().add(DeleteEntryRequested(entryId: entry.id));
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('deleted'.tr())));
  }

  void _openViewStylePicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'View Style',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStyleCard(
                      icon: Icons.article_outlined,
                      label: 'view_normal'.tr(),
                      style: _EntryViewStyle.normal,
                    ),
                    _buildStyleCard(
                      icon: Icons.mail_outline,
                      label: 'view_letter'.tr(),
                      style: _EntryViewStyle.letter,
                    ),
                    _buildStyleCard(
                      icon: Icons.local_library_outlined,
                      label: 'view_library'.tr(),
                      style: _EntryViewStyle.library,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStyleCard({
    required IconData icon,
    required String label,
    required _EntryViewStyle style,
  }) {
    final isSelected = _style == style;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final activeColor = colors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          setState(() {
            _style = style;
            if (_style == _EntryViewStyle.library) {
              _isStickerEditMode = false;
            }
          });
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? activeColor.withValues(alpha: 0.15)
                    : colors.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  isSelected
                      ? activeColor
                      : colors.outlineVariant.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 28,
                color: isSelected ? activeColor : colors.onSurfaceVariant,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? activeColor : colors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAiSummarySheet(JournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'summary'.tr(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (entry.summary != null || _isSummarizing)
                    AiSummaryCard(
                      summary: entry.summary ?? '',
                      isLoading: _isSummarizing,
                      onRefresh: () {
                        Navigator.pop(context);
                        _summarizeEntry(entry);
                      },
                    )
                  else
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${'ai_assistant'.tr()}: ${'generating_summary'.tr()}',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _summarizeEntry(entry);
                            },
                            icon: const Icon(Icons.auto_awesome),
                            label: Text('summarize'.tr()),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showAttachmentsSheet(JournalEntry entry) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;

        return GlassContainer(
          borderRadius: 24,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attachment_rounded,
                      color: colors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'attachments'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (entry.attachmentPaths.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'no_attachments'.tr(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 120,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: entry.attachmentPaths.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final path = entry.attachmentPaths[index];
                        final isImage = isImagePath(path);
                        final normalizedPath = path.replaceAll('\\', '/');
                        final fileName = normalizedPath.split('/').last;

                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              openAttachment(context, path);
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              width: 130,
                              decoration: BoxDecoration(
                                color: colors.surface.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colors.outlineVariant.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child:
                                          isImage
                                              ? Image.file(
                                                File(path),
                                                fit: BoxFit.cover,
                                              )
                                              : Container(
                                                color: colors
                                                    .surfaceContainerHighest
                                                    .withValues(alpha: 0.5),
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
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.surface.withValues(
                                          alpha: 0.85,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        fileName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.labelSmall?.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
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

  String _moodKey(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'happy';
      case Mood.sad:
        return 'sad';
      case Mood.neutral:
        return 'neutral';
      case Mood.excited:
        return 'excited';
      case Mood.angry:
        return 'angry';
    }
  }

  String _getCategoryName(String? categoryId, List<Category> categories) {
    if (categoryId == null) return 'no_category'.tr();
    final cat = categories.firstWhere(
      (c) => c.id == categoryId,
      orElse: () => Category(id: '', name: '', color: 0, iconPath: ''),
    );
    return cat.name.isEmpty ? 'no_category'.tr() : cat.name;
  }

  Widget _buildFloatingTopHeader(
    ThemeData theme,
    JournalEntry entry,
    List<Category> categories,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final locale = context.locale.toString();
    final formattedDate = DateFormat.yMMMMd(locale).format(entry.date);
    final categoryName = _getCategoryName(entry.categoryId, categories);

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
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      _buildHeaderPill(
                        icon: Icons.calendar_month_outlined,
                        label: formattedDate,
                        theme: theme,
                      ),
                      _buildHeaderPill(
                        icon: Icons.mood_outlined,
                        label: 'mood_${_moodKey(entry.mood)}'.tr(),
                        theme: theme,
                      ),
                      _buildHeaderPill(
                        icon: Icons.folder_open_outlined,
                        label: categoryName,
                        theme: theme,
                      ),
                      for (final tag in entry.tags)
                        _buildHeaderPill(
                          icon: Icons.tag_outlined,
                          label: tag,
                          theme: theme,
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderPill({
    required IconData icon,
    required String label,
    required ThemeData theme,
  }) {
    final colors = theme.colorScheme;
    final pillColor = colors.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
    );
  }

  Widget _buildFloatingBottomActionMenu(ThemeData theme, JournalEntry entry) {
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Positioned(
      left: 20,
      right: 20,
      bottom: 20,
      child: GlassContainer(
        borderRadius: 24,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        opacity: isDark ? 0.25 : 0.18,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _bottomActionIcon(
              icon: Icons.visibility_outlined,
              tooltip: 'View Style',
              onTap: _openViewStylePicker,
              theme: theme,
            ),
            _bottomActionIcon(
              icon: Icons.auto_awesome_rounded,
              tooltip: 'summarize'.tr(),
              onTap: () => _showAiSummarySheet(entry),
              theme: theme,
              active: entry.summary != null,
            ),
            _bottomActionIcon(
              icon: Icons.attach_file_rounded,
              tooltip: 'attachments'.tr(),
              onTap: () => _showAttachmentsSheet(entry),
              theme: theme,
              badgeCount:
                  entry.attachmentPaths.isNotEmpty
                      ? entry.attachmentPaths.length
                      : null,
            ),
            if (_style != _EntryViewStyle.library)
              _bottomActionIcon(
                icon:
                    _isStickerEditMode
                        ? Icons.check_circle_rounded
                        : Icons.emoji_emotions_outlined,
                tooltip: 'sticker_edit_mode'.tr(),
                onTap: () {
                  setState(() {
                    _isStickerEditMode = !_isStickerEditMode;
                  });
                },
                theme: theme,
                active: _isStickerEditMode,
              ),
            if (_style != _EntryViewStyle.library && _isStickerEditMode)
              _bottomActionIcon(
                icon: Icons.add_circle_outline_rounded,
                tooltip: 'add_sticker'.tr(),
                onTap: _openStickerPicker,
                theme: theme,
                active: true,
              ),
            _bottomActionIcon(
              icon: Icons.edit_outlined,
              tooltip: 'edit'.tr(),
              onTap:
                  () =>
                      context.push('/home/add-entry?entryId=${widget.entryId}'),
              theme: theme,
            ),
            _bottomActionIcon(
              icon: Icons.delete_outline_rounded,
              tooltip: 'delete'.tr(),
              onTap: () => _confirmDelete(entry),
              theme: theme,
              color: colors.error,
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomActionIcon({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeData theme,
    bool active = false,
    int? badgeCount,
    Color? color,
  }) {
    final colors = theme.colorScheme;
    final baseColor = color ?? colors.onSurfaceVariant;
    final iconColor = active ? colors.primary : baseColor;

    Widget iconWidget = Icon(icon, color: iconColor, size: 24);

    if (badgeCount != null) {
      iconWidget = Badge(
        label: Text(
          badgeCount.toString(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
        ),
        backgroundColor: colors.primary,
        textColor: Colors.white,
        child: iconWidget,
      );
    }

    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(padding: const EdgeInsets.all(10), child: iconWidget),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAttachmentBackdrop = context.select<SettingsBloc, bool>((bloc) {
      final state = bloc.state;
      if (state is SettingsLoaded) return state.settings.showAttachmentBackdrop;
      return AppDefaults.defaultAttachmentBackdrop;
    });

    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, categoryState) {
        final categories =
            categoryState is CategoryLoaded
                ? categoryState.categories
                : <Category>[];

        return BlocBuilder<JournalBloc, JournalState>(
          builder: (context, state) {
            JournalEntry? entry;
            if (state is JournalLoaded) {
              for (final e in state.entries) {
                if (e.id == widget.entryId) {
                  entry = e;
                  break;
                }
              }
            }

            String? backdropPath;
            if (showAttachmentBackdrop && entry != null) {
              for (final path in entry.attachmentPaths) {
                if (isImagePath(path)) {
                  backdropPath = path;
                  break;
                }
              }
            }

            final bodyContent =
                entry == null
                    ? SafeArea(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'entry_not_found'.tr(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    )
                    : Positioned.fill(
                      child: Stack(
                        children: [
                          // Paper background + content
                          Positioned.fill(
                            child: ThemedPaper(
                              applyPageStudio: true,
                              lined: _style != _EntryViewStyle.library,
                              borderRadius: BorderRadius.zero,
                              padding: EdgeInsets.zero,
                              // SizedBox.expand ensures the inner Stack has full
                              // size, so Positioned.fill children render correctly.
                              child: SizedBox.expand(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child:
                                      _style == _EntryViewStyle.letter
                                          ? _LetterView(
                                            key: const ValueKey('letter'),
                                            entry: entry,
                                            stickerController:
                                                _stickerController,
                                            editable: _isStickerEditMode,
                                            onStickersChanged:
                                                _onStickersChanged,
                                          )
                                          : _style == _EntryViewStyle.library
                                          ? _LibraryView(
                                            key: const ValueKey('library'),
                                            entry: entry,
                                          )
                                          : _NormalView(
                                            key: const ValueKey('normal'),
                                            entry: entry,
                                            stickerController:
                                                _stickerController,
                                            editable: _isStickerEditMode,
                                            onStickersChanged:
                                                _onStickersChanged,
                                          ),
                                ),
                              ),
                            ),
                          ),
                          // Floating overlays on top of paper
                          _buildFloatingTopHeader(
                            Theme.of(context),
                            entry,
                            categories,
                          ),
                          _buildFloatingBottomActionMenu(
                            Theme.of(context),
                            entry,
                          ),
                        ],
                      ),
                    );

            return Scaffold(
              extendBodyBehindAppBar: true,
              body: Stack(
                children: [
                  const Positioned.fill(
                    child: ThemedBackdrop(
                      blurSigma: 6,
                      opacity: 0.95,
                      applyPageStudio: true,
                    ),
                  ),
                  if (backdropPath != null)
                    AttachmentBackdrop(path: backdropPath),
                  bodyContent,
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _NormalView extends StatelessWidget {
  const _NormalView({
    super.key,
    required this.entry,
    required this.stickerController,
    required this.editable,
    required this.onStickersChanged,
  });

  final JournalEntry entry;
  final StickerLayerController stickerController;
  final bool editable;
  final ValueChanged<List<EntrySticker>> onStickersChanged;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.patrickHand(
      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 20,
        height: 1.65,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.9),
      ),
    );

    return Stack(
      children: [
        _FullScreenSheet(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
                style: GoogleFonts.patrickHand(
                  textStyle: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 28),
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(entry.content, style: style),
            ],
          ),
        ),
        Positioned.fill(
          child: StickerLayer(
            controller: stickerController,
            editable: editable,
            onChanged: onStickersChanged,
          ),
        ),
      ],
    );
  }
}

class _LetterView extends StatelessWidget {
  const _LetterView({
    super.key,
    required this.entry,
    required this.stickerController,
    required this.editable,
    required this.onStickersChanged,
  });

  final JournalEntry entry;
  final StickerLayerController stickerController;
  final bool editable;
  final ValueChanged<List<EntrySticker>> onStickersChanged;

  @override
  Widget build(BuildContext context) {
    final salutation =
        context.locale.languageCode == 'tr' ? 'Sevgili Günlük,' : 'Dear Diary,';
    final signature =
        context.locale.languageCode == 'tr' ? 'Sevgiyle,' : 'With love,';

    final textStyle = GoogleFonts.caveat(
      textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
        fontSize: 22,
        height: 1.5,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.95),
      ),
    );

    return Stack(
      children: [
        _FullScreenSheet(
          lined: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
                style: GoogleFonts.caveat(
                  textStyle: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold, fontSize: 32),
                ),
              ),
              const SizedBox(height: 8),
              Divider(
                height: 1,
                color: Theme.of(
                  context,
                ).colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              const SizedBox(height: 16),
              Text(
                salutation,
                style: GoogleFonts.caveat(
                  textStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(entry.content, style: textStyle),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        signature,
                        style: GoogleFonts.caveat(
                          textStyle: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat.yMMMMd(
                          context.locale.toString(),
                        ).format(entry.date),
                        style: GoogleFonts.caveat(
                          textStyle: Theme.of(
                            context,
                          ).textTheme.labelMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned.fill(
          child: StickerLayer(
            controller: stickerController,
            editable: editable,
            onChanged: onStickersChanged,
          ),
        ),
      ],
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView({super.key, required this.entry});

  final JournalEntry entry;

  String _moodKey(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return 'happy';
      case Mood.sad:
        return 'sad';
      case Mood.neutral:
        return 'neutral';
      case Mood.excited:
        return 'excited';
      case Mood.angry:
        return 'angry';
    }
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final formattedDate = DateFormat.yMMMMd(locale).add_Hm().format(entry.date);
    final tags = entry.tags.isEmpty ? 'none'.tr() : entry.tags.join(', ');
    final attachmentsCount = entry.attachmentPaths.length;

    final tiles = [
      _LibraryTileData(
        title: entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
        subtitle: formattedDate,
        icon: Icons.menu_book_outlined,
      ),
      _LibraryTileData(
        title: 'mood'.tr(),
        subtitle: 'mood_${_moodKey(entry.mood)}'.tr(),
        icon: Icons.mood_outlined,
      ),
      _LibraryTileData(
        title: 'tags_label'.tr(),
        subtitle: tags,
        icon: Icons.tag_outlined,
      ),
      _LibraryTileData(
        title: 'attachments'.tr(),
        subtitle:
            attachmentsCount == 0 ? 'no_attachments'.tr() : '$attachmentsCount',
        icon: Icons.attach_file_outlined,
      ),
    ];

    return _FullScreenSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxWidth = constraints.maxWidth;
              final columns = maxWidth >= 520 ? 2 : 1;
              final tileWidth = (maxWidth - (columns - 1) * 12) / columns;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final tile in tiles)
                    SizedBox(width: tileWidth, child: _LibraryTile(tile: tile)),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          Divider(
            height: 1,
            color: Theme.of(
              context,
            ).colorScheme.outlineVariant.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 20),
          SelectableText(
            entry.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.75,
              fontSize: 17,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _LibraryTileData {
  const _LibraryTileData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

class _LibraryTile extends StatelessWidget {
  const _LibraryTile({required this.tile});

  final _LibraryTileData tile;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final background = Color.alphaBlend(
      colors.primary.withValues(alpha: 0.08),
      colors.surface,
    );

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(tile.icon, size: 20, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tile.title,
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  tile.subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenSheet extends StatelessWidget {
  const _FullScreenSheet({required this.child, this.lined = false});

  final Widget child;
  final bool lined;
  static const EdgeInsetsGeometry padding = EdgeInsets.fromLTRB(
    28,
    120,
    28,
    160,
  );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final minInnerHeight = (constraints.maxHeight - padding.vertical).clamp(
          0.0,
          double.infinity,
        );
        return Padding(
          padding: padding,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minInnerHeight),
              child: child,
            ),
          ),
        );
      },
    );
  }
}
