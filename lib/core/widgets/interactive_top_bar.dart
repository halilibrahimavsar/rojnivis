import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../features/journal/domain/entities/journal_filter.dart';
import '../../features/journal/presentation/bloc/journal_bloc.dart';
import '../../features/journal/presentation/widgets/filter_dialog.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../theme/app_theme.dart';
import 'glass_overlays.dart';

enum TopBarMode { none, search, mood }

class InteractiveTopBar extends StatefulWidget {
  const InteractiveTopBar({super.key});

  @override
  State<InteractiveTopBar> createState() => _InteractiveTopBarState();
}

class _InteractiveTopBarState extends State<InteractiveTopBar> {
  TopBarMode _mode = TopBarMode.none;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    final state = context.read<JournalBloc>().state;
    JournalFilter currentFilter = const JournalFilter();
    if (state is JournalLoaded) {
      currentFilter = state.filter;
    }

    context.read<JournalBloc>().add(
      SearchRequested(filter: currentFilter.copyWith(query: value)),
    );
  }

  Future<void> _showFilterDialog() async {
    final state = context.read<JournalBloc>().state;
    JournalFilter currentFilter = const JournalFilter();
    if (state is JournalLoaded) {
      currentFilter = state.filter;
    }

    final result = await showDialog<JournalFilter>(
      context: context,
      builder: (context) => FilterDialog(initialFilter: currentFilter),
    );

    if (result != null) {
      if (!mounted) return;
      context.read<JournalBloc>().add(
        SearchRequested(filter: result.copyWith(query: _searchController.text)),
      );
    }
  }

  void _closeExpanded() {
    setState(() {
      _mode = TopBarMode.none;
    });
    if (_searchController.text.isNotEmpty) {
      _searchController.clear();
      _onSearchChanged('');
    }
    _searchFocus.unfocus();
  }

  void _openSearch() {
    setState(() {
      _mode = TopBarMode.search;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  void _openMood() {
    setState(() {
      _mode = TopBarMode.mood;
    });
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final isJournalPage = location == '/home' || location == '/';

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final buttonWidth = 56.0;
        final expandedWidth = maxWidth;

        final searchWidth =
            _mode == TopBarMode.search
                ? expandedWidth
                : (_mode == TopBarMode.none && isJournalPage
                    ? buttonWidth
                    : 0.0);
        final themeWidth =
            _mode == TopBarMode.mood
                ? expandedWidth
                : (_mode == TopBarMode.none && isJournalPage
                    ? buttonWidth
                    : 0.0);

        return SizedBox(
          height: 56,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Search Button / Bar
              Positioned(
                left: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: searchWidth,
                  height: 56,
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child:
                      searchWidth == 0.0
                          ? const SizedBox.shrink()
                          : GestureDetector(
                            onTap:
                                _mode == TopBarMode.none ? _openSearch : null,
                            child: GlassContainer(
                              padding: EdgeInsets.zero,
                              borderRadius: 28,
                              child: OverflowBox(
                                alignment: Alignment.centerLeft,
                                minWidth: buttonWidth,
                                maxWidth: maxWidth,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: buttonWidth,
                                      height: 56,
                                      child: const Icon(Icons.search, size: 20),
                                    ),
                                    if (_mode == TopBarMode.search) ...[
                                      Expanded(
                                        child: TextField(
                                          controller: _searchController,
                                          focusNode: _searchFocus,
                                          onChanged: _onSearchChanged,
                                          style:
                                              Theme.of(
                                                context,
                                              ).textTheme.bodyMedium,
                                          decoration: InputDecoration(
                                            hintText: 'search_hint'.tr(),
                                            border: InputBorder.none,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.filter_list_outlined,
                                          size: 20,
                                        ),
                                        onPressed: _showFilterDialog,
                                        tooltip: 'filter'.tr(),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: _closeExpanded,
                                      ),
                                      const SizedBox(width: 8),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                ),
              ),

              // Centralized Toggle
              if (_mode == TopBarMode.none && isJournalPage)
                Positioned(
                  child: BlocBuilder<JournalBloc, JournalState>(
                    builder: (context, state) {
                      final viewMode =
                          state is JournalLoaded
                              ? state.viewMode
                              : JournalViewMode.list;

                      return GlassContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        borderRadius: 28,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _ToggleButton(
                              icon: Icons.view_list_rounded,
                              isSelected: viewMode == JournalViewMode.list,
                              tooltip: 'list_view'.tr(),
                              onTap:
                                  () => context.read<JournalBloc>().add(
                                    const ChangeViewModeRequested(
                                      viewMode: JournalViewMode.list,
                                    ),
                                  ),
                            ),
                            _ToggleButton(
                              icon: Icons.grid_view_rounded,
                              isSelected: viewMode == JournalViewMode.grid,
                              tooltip: 'grid_view'.tr(),
                              onTap:
                                  () => context.read<JournalBloc>().add(
                                    const ChangeViewModeRequested(
                                      viewMode: JournalViewMode.grid,
                                    ),
                                  ),
                            ),
                            _ToggleButton(
                              icon: Icons.calendar_month_rounded,
                              isSelected: viewMode == JournalViewMode.calendar,
                              tooltip: 'calendar_view'.tr(),
                              onTap:
                                  () => context.read<JournalBloc>().add(
                                    const ChangeViewModeRequested(
                                      viewMode: JournalViewMode.calendar,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

              // Theme Selector
              Positioned(
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  width: themeWidth,
                  height: 56,
                  alignment: Alignment.centerRight,
                  clipBehavior: Clip.hardEdge,
                  decoration: const BoxDecoration(),
                  child:
                      themeWidth == 0.0
                          ? const SizedBox.shrink()
                          : GestureDetector(
                            onTap: _mode == TopBarMode.none ? _openMood : null,
                            child: GlassContainer(
                              padding: EdgeInsets.zero,
                              borderRadius: 28,
                              child: OverflowBox(
                                alignment: Alignment.centerRight,
                                minWidth: buttonWidth,
                                maxWidth: maxWidth,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (_mode == TopBarMode.mood) ...[
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: BlocBuilder<
                                          SettingsBloc,
                                          SettingsState
                                        >(
                                          builder: (context, state) {
                                            final currentPreset =
                                                state is SettingsLoaded
                                                    ? state.effectiveThemePreset
                                                    : AppTheme.presets.first.id;

                                            return SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                children:
                                                    AppTheme.presets.map((
                                                      preset,
                                                    ) {
                                                      final isSelected =
                                                          currentPreset ==
                                                          preset.id;
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets.only(
                                                              right: 8.0,
                                                            ),
                                                        child: ChoiceChip(
                                                          label: Text(
                                                            preset.labelKey
                                                                .tr(),
                                                          ),
                                                          selected: isSelected,
                                                          avatar: Container(
                                                            width: 14,
                                                            height: 14,
                                                            decoration: BoxDecoration(
                                                              color:
                                                                  preset
                                                                      .previewColor,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                          ),
                                                          onSelected: (_) {
                                                            context
                                                                .read<
                                                                  SettingsBloc
                                                                >()
                                                                .add(
                                                                  UpdateThemePreset(
                                                                    preset.id,
                                                                  ),
                                                                );
                                                            context
                                                                .read<
                                                                  SettingsBloc
                                                                >()
                                                                .add(
                                                                  const UpdateRandomThemeEnabled(
                                                                    false,
                                                                  ),
                                                                );
                                                            _closeExpanded();
                                                          },
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            );
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        onPressed: _closeExpanded,
                                      ),
                                    ],
                                    SizedBox(
                                      width: buttonWidth,
                                      height: 56,
                                      child: const Icon(
                                        Icons.palette_outlined,
                                        size: 20,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(8),
          margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
          decoration: BoxDecoration(
            color:
                isSelected ? colorScheme.primary.withValues(alpha: 0.2) : null,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
