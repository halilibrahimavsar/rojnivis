import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/insights_entity.dart';
import '../../../journal/domain/entities/journal_entry.dart';
import '../bloc/insights_bloc.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('insights'.tr()),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: BlocBuilder<InsightsBloc, InsightsState>(
        builder: (context, state) {
          if (state is InsightsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InsightsError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Text(state.message, textAlign: TextAlign.center),
              ),
            );
          }

          if (state is! InsightsLoaded) {
            return const SizedBox.shrink();
          }

          final insights = state.insights;

          if (insights.totalEntries == 0) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_edu,
                    size: 64,
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'no_insights_yet'.tr(),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'start_writing_to_see_insights'.tr(),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildStatsGrid(context, insights),
              const SizedBox(height: 24),
              _buildMoodDistribution(context, insights),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, InsightsEntity insights) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _StatCard(
          label: 'total_entries'.tr(),
          value: insights.totalEntries.toString(),
          icon: Icons.book_outlined,
          color: Colors.blue,
        ),
        _StatCard(
          label: 'total_words'.tr(),
          value: insights.totalWords.toString(),
          icon: Icons.text_fields_outlined,
          color: Colors.orange,
        ),
        _StatCard(
          label: 'avg_words'.tr(),
          value:
              (insights.totalEntries > 0
                      ? (insights.totalWords / insights.totalEntries).round()
                      : 0)
                  .toString(),
          icon: Icons.analytics_outlined,
          color: Colors.green,
        ),
        _StatCard(
          label: 'active_days'.tr(),
          value:
              insights.moodDistribution.values
                  .fold(0, (a, b) => a + b)
                  .toString(),
          icon: Icons.calendar_today_outlined,
          color: Colors.purple,
        ),
      ],
    );
  }

  Widget _buildMoodDistribution(BuildContext context, InsightsEntity insights) {
    final sortedMoods =
        insights.moodDistribution.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'mood_distribution'.tr(),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (sortedMoods.isEmpty)
            Text('no_data'.tr())
          else
            ...sortedMoods.map((entry) {
              final mood = Mood.values.firstWhere(
                (m) => m.name == entry.key,
                orElse: () => Mood.neutral,
              );
              final percentage = (entry.value / insights.totalEntries);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text('mood_${entry.key}'.tr()),
                        const Spacer(),
                        Text('${(percentage * 100).round()}%'),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: percentage,
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color.withValues(alpha: 0.7), size: 20),
          const Spacer(),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
