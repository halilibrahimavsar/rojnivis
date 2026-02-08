import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';

import '../../domain/entities/journal_entry.dart';
import '../bloc/journal_bloc.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/presentation/bloc/category_bloc.dart';

class EntryDetailPage extends StatefulWidget {
  final String entryId;

  const EntryDetailPage({super.key, required this.entryId});

  @override
  State<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends State<EntryDetailPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<JournalBloc, JournalState>(
        builder: (context, state) {
          if (state is JournalLoaded) {
            final entry = state.entries.firstWhere(
              (e) => e.id == widget.entryId,
              orElse: () => throw Exception('Entry not found'),
            );

            return Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      Theme.of(context).brightness == Brightness.light
                          ? [Colors.white, Colors.grey.shade100]
                          : [Colors.grey.shade900, Colors.black],
                ),
              ),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    slivers: [
                      _buildAppBar(context, entry),
                      SliverToBoxAdapter(child: _buildContent(context, entry)),
                    ],
                  ),
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, JournalEntry entry) {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          entry.title,
          style: const TextStyle(
            shadows: [
              Shadow(
                offset: Offset(0, 2),
                blurRadius: 4,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF6C5CE7).withOpacity(0.8),
                const Color(0xFF00CEC9).withOpacity(0.6),
              ],
            ),
          ),
          child: Center(
            child: Icon(
              _getMoodIcon(entry.mood),
              size: 80,
              color: Colors.white.withOpacity(0.3),
            ),
          ),
        ),
      ),
      actions: [
        IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.delete),
          onPressed: () => _deleteEntry(context, entry),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, JournalEntry entry) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildMetaInfo(context, entry),
            const SizedBox(height: 16),
            _buildCategoryInfo(context, entry),
            const SizedBox(height: 24),
            _buildMoodIndicator(context, entry),
            const SizedBox(height: 24),
            _buildContentText(context, entry),
            const SizedBox(height: 24),
            _buildTags(context, entry),
            const SizedBox(height: 24),
            _buildAttachments(context, entry),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaInfo(BuildContext context, JournalEntry entry) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetaItem(
            context,
            Icons.calendar_today,
            DateFormat.yMMMd().format(entry.date),
          ),
          _buildMetaItem(
            context,
            Icons.access_time,
            DateFormat.Hm().format(entry.date),
          ),
          _buildMetaItem(
            context,
            _getMoodIcon(entry.mood),
            entry.mood.name.toString().split('.').last.capitalize(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaItem(BuildContext context, IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(text, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }

  Widget _buildCategoryInfo(BuildContext context, JournalEntry entry) {
    return BlocBuilder<CategoryBloc, CategoryState>(
      builder: (context, state) {
        if (state is CategoryLoaded && entry.categoryId != null) {
          final category = state.categories.firstWhere(
            (c) => c.id == entry.categoryId,
            orElse: () => Category(id: '', name: '', color: 0, iconPath: ''),
          );

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(category.color).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(category.color),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  category.name,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Color(category.color),
                  ),
                ),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildMoodIndicator(BuildContext context, JournalEntry entry) {
    final moodColors = {
      Mood.happy: Colors.green,
      Mood.sad: Colors.blue,
      Mood.neutral: Colors.grey,
      Mood.excited: Colors.orange,
      Mood.angry: Colors.red,
    };

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: moodColors[entry.mood]?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: moodColors[entry.mood] ?? Colors.grey,
          width: 2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _getMoodIcon(entry.mood),
            size: 32,
            color: moodColors[entry.mood],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'mood'.tr() +
                  ': ' +
                  entry.mood.name.toString().split('.').last.capitalize(),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentText(BuildContext context, JournalEntry entry) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        entry.content,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
      ),
    );
  }

  Widget _buildTags(BuildContext context, JournalEntry entry) {
    if (entry.tags.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('tags_label'.tr(), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              entry.tags.map((tag) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.primary.withOpacity(0.6),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '#$tag',
                    style: Theme.of(
                      context,
                    ).textTheme.labelMedium?.copyWith(color: Colors.white),
                  ),
                );
              }).toList(),
        ),
      ],
    );
  }

  Widget _buildAttachments(BuildContext context, JournalEntry entry) {
    if (entry.attachmentPaths.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attachments', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children:
              entry.attachmentPaths.map((path) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getAttachmentIcon(path),
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        path.split('/').last,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ],
                  ),
                );
              }).toList(),
        ),
      ],
    );
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

  void _deleteEntry(BuildContext context, JournalEntry entry) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_confirmation'.tr()),
            content: Text('delete_entry_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  context.read<JournalBloc>().add(
                    DeleteJournalEntryEvent(entry.id),
                  );
                  context.pop();
                  context.pop();
                },
                child: Text('delete'.tr()),
              ),
            ],
          ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
