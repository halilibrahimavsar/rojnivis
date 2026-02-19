import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/page_studio_models.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../bloc/settings_bloc.dart';

class PageStudioPage extends StatelessWidget {
  const PageStudioPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('page_studio'.tr())),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is! SettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final visualFamily = PageVisualFamilyX.fromId(state.pageVisualFamily);
          final variant = VintagePaperVariantX.fromId(state.vintagePaperVariant);
          final intensity = AnimationIntensityX.fromId(state.animationIntensity);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'page_visual_family'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<PageVisualFamily>(
                      segments: [
                        ButtonSegment(
                          value: PageVisualFamily.classic,
                          label: Text('classic'.tr()),
                          icon: const Icon(Icons.style_outlined),
                        ),
                        ButtonSegment(
                          value: PageVisualFamily.vintage,
                          label: Text('vintage'.tr()),
                          icon: const Icon(Icons.auto_stories_outlined),
                        ),
                      ],
                      selected: {visualFamily},
                      onSelectionChanged: (selection) {
                        context.read<SettingsBloc>().add(
                              UpdatePageVisualFamily(selection.first.id),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'vintage_paper_variant'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _variantChip(
                          context,
                          variant,
                          VintagePaperVariant.parchment,
                          'variant_parchment'.tr(),
                          visualFamily == PageVisualFamily.vintage,
                        ),
                        _variantChip(
                          context,
                          variant,
                          VintagePaperVariant.sepiaDiary,
                          'variant_sepia_diary'.tr(),
                          visualFamily == PageVisualFamily.vintage,
                        ),
                        _variantChip(
                          context,
                          variant,
                          VintagePaperVariant.pressedFloral,
                          'variant_pressed_floral'.tr(),
                          visualFamily == PageVisualFamily.vintage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'animation_intensity'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<AnimationIntensity>(
                      segments: [
                        ButtonSegment(
                          value: AnimationIntensity.off,
                          label: Text('animation_off'.tr()),
                        ),
                        ButtonSegment(
                          value: AnimationIntensity.subtle,
                          label: Text('animation_subtle'.tr()),
                        ),
                        ButtonSegment(
                          value: AnimationIntensity.cinematic,
                          label: Text('animation_cinematic'.tr()),
                        ),
                      ],
                      selected: {intensity},
                      onSelectionChanged: (selection) {
                        context.read<SettingsBloc>().add(
                              UpdateAnimationIntensity(selection.first.id),
                            );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              AppCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'live_preview'.tr(),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ThemedPaper(
                      lined: true,
                      minHeight: 180,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'preview_title'.tr(),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'preview_body'.tr(),
                            style: Theme.of(context).textTheme.bodyLarge,
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

  Widget _variantChip(
    BuildContext context,
    VintagePaperVariant selected,
    VintagePaperVariant variant,
    String label,
    bool enabled,
  ) {
    return ChoiceChip(
      label: Text(label),
      selected: selected == variant,
      onSelected: !enabled
          ? null
          : (_) {
              context
                  .read<SettingsBloc>()
                  .add(UpdateVintagePaperVariant(variant.id));
            },
    );
  }
}
