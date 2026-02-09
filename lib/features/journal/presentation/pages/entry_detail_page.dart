import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/attachment_backdrop.dart';
import '../../../../core/widgets/attachment_preview.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../../data/models/journal_entry_model.dart';
import '../bloc/journal_bloc.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

enum _EntryViewStyle { normal, letter, library }

const _compactDensity = VisualDensity(horizontal: -2, vertical: -2);

class EntryDetailPage extends StatefulWidget {
  const EntryDetailPage({super.key, required this.entryId});

  final String entryId;

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage> {
  _EntryViewStyle _style = _EntryViewStyle.letter;

  Future<void> _confirmDelete(JournalEntryModel entry) async {
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

  @override
  Widget build(BuildContext context) {
    final showAttachmentBackdrop = context.select<SettingsBloc, bool>((bloc) {
      final state = bloc.state;
      if (state is SettingsLoaded) return state.showAttachmentBackdrop;
      return AppDefaults.defaultAttachmentBackdrop;
    });

    return BlocBuilder<JournalBloc, JournalState>(
      builder: (context, state) {
        JournalEntryModel? entry;
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
                : SafeArea(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Header(entry: entry),
                            const SizedBox(height: 12),
                            SegmentedButton<_EntryViewStyle>(
                              segments: [
                                ButtonSegment(
                                  value: _EntryViewStyle.normal,
                                  label: Text('view_normal'.tr()),
                                  icon: const Icon(Icons.article_outlined),
                                ),
                                ButtonSegment(
                                  value: _EntryViewStyle.letter,
                                  label: Text('view_letter'.tr()),
                                  icon: const Icon(Icons.mail_outline),
                                ),
                                ButtonSegment(
                                  value: _EntryViewStyle.library,
                                  label: Text('view_library'.tr()),
                                  icon: const Icon(
                                    Icons.local_library_outlined,
                                  ),
                                ),
                              ],
                              selected: {_style},
                              style: ButtonStyle(
                                visualDensity: _compactDensity,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                minimumSize: const MaterialStatePropertyAll(
                                  Size(0, 0),
                                ),
                                padding: const MaterialStatePropertyAll(
                                  EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                ),
                              ),
                              onSelectionChanged: (selection) {
                                setState(() => _style = selection.first);
                              },
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child:
                                _style == _EntryViewStyle.letter
                                    ? _LetterView(
                                      key: const ValueKey('letter'),
                                      entry: entry,
                                    )
                                    : _style == _EntryViewStyle.library
                                    ? _LibraryView(
                                      key: const ValueKey('library'),
                                      entry: entry,
                                    )
                                    : _NormalView(
                                      key: const ValueKey('normal'),
                                      entry: entry,
                                    ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );

        return Scaffold(
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            title: Text('entry'.tr()),
            actions:
                entry == null
                    ? null
                    : [
                      IconButton(
                        onPressed:
                            () => context.push(
                              '/add-entry?entryId=${widget.entryId}',
                            ),
                        icon: const Icon(Icons.edit_outlined),
                        tooltip: 'edit'.tr(),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(entry!),
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'delete'.tr(),
                      ),
                      const SizedBox(width: 4),
                    ],
          ),
          body: Stack(
            children: [
              const Positioned.fill(
                child: ThemedBackdrop(blurSigma: 6, opacity: 0.95),
              ),
              if (backdropPath != null) AttachmentBackdrop(path: backdropPath),
              bodyContent,
            ],
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.entry});

  final JournalEntryModel entry;

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

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final formattedDate = DateFormat.yMMMMEEEEd(
      locale,
    ).add_Hm().format(entry.date);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          entry.title.trim().isEmpty ? 'untitled'.tr() : entry.title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Icon(
              Icons.calendar_month_outlined,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                formattedDate,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(
              label: Text('mood_${_moodKey(entry.moodIndex)}'.tr()),
              avatar: const Icon(Icons.mood_outlined, size: 18),
              visualDensity: _compactDensity,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              labelPadding: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            ),
            for (final tag in entry.tags)
              Chip(
                label: Text(tag),
                avatar: const Icon(Icons.tag_outlined, size: 18),
                visualDensity: _compactDensity,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              ),
          ],
        ),
        if (entry.attachmentPaths.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'attachments'.tr(),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final maxLabelWidth = (constraints.maxWidth - 96).clamp(
                120.0,
                constraints.maxWidth,
              );
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final path in entry.attachmentPaths)
                    Tooltip(
                      message: _fileName(path),
                      child: ActionChip(
                        label: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxLabelWidth),
                          child: Text(
                            _fileName(path),
                            softWrap: false,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        avatar: Icon(_attachmentIcon(path), size: 18),
                        visualDensity: _compactDensity,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        onPressed: () => openAttachment(context, path),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ],
    );
  }
}

class _NormalView extends StatelessWidget {
  const _NormalView({super.key, required this.entry});

  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context) {
    return _FullScreenSheet(
      child: Text(entry.content, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}

class _LetterView extends StatelessWidget {
  const _LetterView({super.key, required this.entry});

  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final salutation =
        context.locale.languageCode == 'tr' ? 'Sevgili Günlük,' : 'Dear Diary,';
    final signature =
        context.locale.languageCode == 'tr' ? 'Sevgiyle,' : 'With love,';

    return _FullScreenSheet(
      lined: true,
      child: DefaultTextStyle.merge(
        style: GoogleFonts.playfairDisplay(
          textStyle: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(height: 1.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              salutation,
              style: GoogleFonts.playfairDisplay(
                textStyle: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 12),
            Text(entry.content),
            const SizedBox(height: 18),
            Text(
              signature,
              style: GoogleFonts.playfairDisplay(
                textStyle: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LibraryView extends StatelessWidget {
  const _LibraryView({super.key, required this.entry});

  final JournalEntryModel entry;

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
        subtitle: 'mood_${_moodKey(entry.moodIndex)}'.tr(),
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
      child: LayoutBuilder(
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
  const _FullScreenSheet({
    required this.child,
    this.lined = false,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 20),
  });

  final Widget child;
  final bool lined;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final resolved =
        padding is EdgeInsets ? padding as EdgeInsets : const EdgeInsets.all(0);
    return LayoutBuilder(
      builder: (context, constraints) {
        final minInnerHeight = (constraints.maxHeight - resolved.vertical)
            .clamp(0.0, double.infinity);
        return ThemedPaper(
          lined: lined,
          minHeight: constraints.maxHeight,
          padding: resolved,
          child: SingleChildScrollView(
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
