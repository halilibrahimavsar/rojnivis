import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';
import 'package:unified_flutter_features/features/local_auth/presentation/widgets/local_auth_settings_widget.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../di/injection.dart';
import '../bloc/settings_bloc.dart';
import '../../../../core/widgets/notebook_cover.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final fonts = AppTheme.supportedFonts;
    final presets = AppTheme.presets;

    return Scaffold(
      appBar: AppBar(title: Text('settings'.tr())),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              _Section(
                title: 'theme'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'theme_mode'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<ThemeMode>(
                      segments: [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('system'.tr()),
                          icon: const Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('light'.tr()),
                          icon: const Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('dark'.tr()),
                          icon: const Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {state.themeMode},
                      onSelectionChanged: (selection) {
                        context.read<SettingsBloc>().add(
                          UpdateThemeMode(selection.first),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'theme_style'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final preset in presets)
                          ChoiceChip(
                            label: Text(preset.labelKey.tr()),
                            selected: state.themePreset == preset.id,
                            avatar: Container(
                              width: 14,
                              height: 14,
                              decoration: BoxDecoration(
                                color: preset.previewColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            onSelected:
                                (_) => context.read<SettingsBloc>().add(
                                  UpdateThemePreset(preset.id),
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      value: state.showAttachmentBackdrop,
                      onChanged:
                          (value) => context.read<SettingsBloc>().add(
                            UpdateAttachmentBackdrop(value),
                          ),
                      title: Text('attachment_backdrop'.tr()),
                      subtitle: Text('attachment_backdrop_desc'.tr()),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'notebook_customization'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: SizedBox(
                        width: 140,
                        height: 180,
                        child: NotebookCover(
                          color: Color(state.notebookCoverColor),
                          texture: state.notebookCoverTexture,
                          child: Center(
                            child: Text(
                              'Rojnivis',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Caveat',
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'cover_color'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        for (final color in [
                          0xFF2C3E50,
                          0xFFC0392B,
                          0xFF27AE60,
                          0xFF8E44AD,
                          0xFFD35400,
                        ])
                          GestureDetector(
                            onTap:
                                () => context.read<SettingsBloc>().add(
                                  UpdateNotebookCoverColor(color),
                                ),
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      state.notebookCoverColor == color
                                          ? Theme.of(
                                            context,
                                          ).colorScheme.primary
                                          : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'cover_texture'.tr(),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 10),
                    SegmentedButton<String>(
                      segments: [
                        ButtonSegment(
                          value: 'classic',
                          label: Text('texture_classic'.tr()),
                        ),
                        ButtonSegment(
                          value: 'leather',
                          label: Text('texture_leather'.tr()),
                        ),
                        ButtonSegment(
                          value: 'fabric',
                          label: Text('texture_fabric'.tr()),
                        ),
                      ],
                      selected: {state.notebookCoverTexture},
                      onSelectionChanged: (selection) {
                        context.read<SettingsBloc>().add(
                          UpdateNotebookCoverTexture(selection.first),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'language'.tr(),
                child: SegmentedButton<Locale>(
                  segments: [
                    ButtonSegment(
                      value: const Locale('tr', 'TR'),
                      label: const Text('Türkçe'),
                    ),
                    ButtonSegment(
                      value: const Locale('en', 'US'),
                      label: const Text('English'),
                    ),
                  ],
                  selected: {context.locale},
                  onSelectionChanged: (selection) {
                    final locale = selection.first;
                    context.setLocale(locale);
                    context.read<SettingsBloc>().add(UpdateLocale(locale));
                  },
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'typography'.tr(),
                child: DropdownButtonFormField<String>(
                  value:
                      fonts.contains(state.fontFamily)
                          ? state.fontFamily
                          : fonts.first,
                  items: fonts
                      .map((f) => DropdownMenuItem(value: f, child: Text(f)))
                      .toList(growable: false),
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<SettingsBloc>().add(UpdateFontFamily(value));
                  },
                  decoration: InputDecoration(
                    labelText: 'font'.tr(),
                    prefixIcon: const Icon(Icons.text_fields_outlined),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _Section(
                title: 'security'.tr(),
                child: LocalAuthSettingsWidget(
                  repository: getIt<LocalAuthRepository>(),
                  showHeader: false, // We have our own section header
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
