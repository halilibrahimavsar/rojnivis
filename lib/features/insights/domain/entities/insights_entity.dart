import 'package:equatable/equatable.dart';

class InsightsEntity extends Equatable {
  final int totalEntries;
  final int totalWords;
  final Map<String, int> moodDistribution;

  const InsightsEntity({
    required this.totalEntries,
    required this.totalWords,
    required this.moodDistribution,
  });

  factory InsightsEntity.empty() => const InsightsEntity(
    totalEntries: 0,
    totalWords: 0,
    moodDistribution: {},
  );

  @override
  List<Object?> get props => [totalEntries, totalWords, moodDistribution];
}
