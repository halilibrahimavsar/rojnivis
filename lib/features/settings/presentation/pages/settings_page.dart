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
import '../../../../core/services/ai_service.dart';

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
              const SizedBox(height: 12),
              _Section(
                title: 'ai_assistant'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ai_api_key_desc'.tr(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      initialValue: state.aiApiKey,
                      decoration: InputDecoration(
                        labelText: 'gemini_api_key'.tr(),
                        hintText: 'AI_API_KEY',
                        prefixIcon: const Icon(Icons.vpn_key_outlined),
                        suffixIcon: const Icon(Icons.auto_awesome),
                      ),
                      onChanged: (value) {
                        // We use onChanged to update state as user types or pastes
                        context.read<SettingsBloc>().add(UpdateAiApiKey(value));
                      },
                      onFieldSubmitted: (value) {
                        context.read<SettingsBloc>().add(UpdateAiApiKey(value));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('api_key_updated'.tr())),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Model Seçimi
                    Text(
                      'ai_model'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModelSelector(),
                    const SizedBox(height: 16),

                    // Kota Bilgisi
                    _buildQuotaInfo(),
                    const SizedBox(height: 12),

                    Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        spacing: 8,
                        children: [
                          TextButton.icon(
                            onPressed: () async {
                              final service = getIt<AiService>();
                              if (!service.isConfigured) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('api_key_required'.tr()),
                                  ),
                                );
                                return;
                              }

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder:
                                    (c) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                              );

                              try {
                                final models =
                                    await service.listAvailableModels();
                                if (context.mounted) {
                                  Navigator.pop(context); // Pop loading
                                  showDialog(
                                    context: context,
                                    builder:
                                        (c) => AlertDialog(
                                          title: Text('ai_model_status'.tr()),
                                          content: SingleChildScrollView(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                if (models.any(
                                                  (m) =>
                                                      !m.contains('Error') &&
                                                      !m.contains(
                                                        'No working',
                                                      ) &&
                                                      !m.contains(':'),
                                                ))
                                                  Text(
                                                    '✅ ${'ai_available'.tr()}',
                                                    style: const TextStyle(
                                                      color: Colors.green,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  )
                                                else
                                                  Text(
                                                    '❌ ${'ai_unavailable'.tr()}',
                                                    style: const TextStyle(
                                                      color: Colors.red,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                const SizedBox(height: 8),
                                                Text('${'ai_models'.tr()}:'),
                                                const SizedBox(height: 4),
                                                ...models.map((m) {
                                                  final isError =
                                                      m.contains(':') ||
                                                      m.contains(
                                                        'No working',
                                                      ) ||
                                                      m.contains('Kota');
                                                  return Text(
                                                    isError ? '⚠️ $m' : '✅ $m',
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          isError
                                                              ? Colors.orange
                                                              : Colors
                                                                  .green[700],
                                                    ),
                                                  );
                                                }),
                                              ],
                                            ),
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(c),
                                              child: Text('close'.tr()),
                                            ),
                                          ],
                                        ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  Navigator.pop(context); // Pop loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${'error'.tr()}: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.wifi_find),
                            label: Text('test_connection'.tr()),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildModelSelector() {
    return FutureBuilder<List<ModelInfo>>(
      future: Future.value(getIt<AiService>().availableModels),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final models = snapshot.data!;
        final service = getIt<AiService>();
        final currentModel = service.selectedModel;

        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: models.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final model = models[index];
              final isSelected = model.id == currentModel;

              return RadioListTile<String>(
                title: Text(model.displayName),
                subtitle: Text(
                  '${model.description}${model.quotaLimit != null ? ' (${model.quotaLimit}/gün)' : ''}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                value: model.id,
                groupValue: currentModel,
                onChanged: (value) async {
                  if (value != null) {
                    await service.setModel(value);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${'ai_model_changed'.tr()}: ${model.displayName}',
                          ),
                        ),
                      );
                    }
                  }
                },
                secondary:
                    isSelected
                        ? Icon(
                          Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary,
                        )
                        : null,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildQuotaInfo() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: getIt<AiService>().getQuotaInfo(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox.shrink();
        }

        final quota = snapshot.data!;
        final remaining = quota['remaining'] as int? ?? 0;
        final used = quota['used'] as int? ?? 0;
        final limit = quota['limit'] as int? ?? 1000;

        final percentage = limit > 0 ? (used / limit) : 0.0;
        final color =
            percentage > 0.8
                ? Colors.red
                : percentage > 0.5
                ? Colors.orange
                : Colors.green;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.speed,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'ai_quota'.tr(),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${'ai_used'.tr()}: $used / $limit',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${'ai_remaining'.tr()}: $remaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (percentage > 0.8) ...[
                const SizedBox(height: 4),
                Text(
                  'ai_quota_warning'.tr(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ],
          ),
        );
      },
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
