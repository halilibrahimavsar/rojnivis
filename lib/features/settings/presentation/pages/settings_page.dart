import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
                title: 'account_security'.tr(),
                child: Column(
                  children: [
                    _SettingsButton(
                      valid: true,
                      icon: Icons.manage_accounts,
                      title: 'remote_auth_settings'.tr(), // "Remote Account"
                      subtitle:
                          'remote_auth_desc'
                              .tr(), // "Manage your cloud account"
                      onTap: () => context.push('/home/settings/remote-auth'),
                    ),
                    const SizedBox(height: 12),
                    _SettingsButton(
                      valid: true,
                      icon: Icons.fingerprint,
                      title: 'local_auth_settings'.tr(), // "Local Security"
                      subtitle: 'local_auth_desc'.tr(), // "PIN and Biometrics"
                      onTap: () => context.push('/home/settings/local-auth'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
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
                title: 'ai_assistant'.tr(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ai_model'.tr(),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildModelSelector(),
                    const SizedBox(height: 16),
                    
                    // Connection Status & Test
                    FutureBuilder<AiServiceStatus>(
                      future: getIt<AiService>().getStatus(),
                      builder: (context, snapshot) {
                        final status = snapshot.data;
                        final isConfigured = status?.isConfigured ?? false;
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  isConfigured ? Icons.check_circle : Icons.error,
                                  color: isConfigured ? Colors.green : Colors.orange,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    isConfigured 
                                      ? 'AI Servisi Hazır (Remote Config)' 
                                      : 'AI Servisi Yapılandırılmadı',
                                    style: TextStyle(
                                      color: isConfigured ? Colors.green : Colors.orange,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (!isConfigured) ...[
                              const SizedBox(height: 4),
                              Text(
                                'İnternet bağlantınızı kontrol edin ve uygulamanın güncel olduğundan emin olun.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () async {
                          showDialog(
                            context: context,
                            barrierDismissible: false,
                            builder: (c) => const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );

                          try {
                            // Force refresh config
                            await getIt<AiService>().init();
                            final service = getIt<AiService>();
                            final models = await service.listAvailableModels();
                            
                            if (context.mounted) {
                              Navigator.pop(context); // Pop loading
                              showDialog(
                                context: context,
                                builder: (c) => AlertDialog(
                                  title: Text('ai_model_status'.tr()),
                                  content: SingleChildScrollView(
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (service.isConfigured)
                                          Text(
                                            '✅ ${'ai_available'.tr()}',
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        else
                                          Text(
                                            '❌ ${'ai_unavailable'.tr()}',
                                            style: const TextStyle(
                                              color: Colors.red,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text('${'ai_models'.tr()}:'),
                                        const SizedBox(height: 4),
                                        ...models.map((m) {
                                          final isError = m.contains(':') || 
                                              m.contains('No working') || 
                                              m.contains('Kota');
                                          return Text(
                                            isError ? '⚠️ $m' : '✅ $m',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isError ? Colors.orange : Colors.green[700],
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
                                SnackBar(content: Text('${'error'.tr()}: $e')),
                              );
                            }
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: Text('Bağlantıyı Kontrol Et'),
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
                  model.description,
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

}

class _SettingsButton extends StatelessWidget {
  const _SettingsButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.valid,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool valid;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color:
                valid
                    ? Theme.of(context).colorScheme.outlineVariant
                    : Theme.of(context).colorScheme.error,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
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
