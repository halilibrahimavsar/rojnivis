import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../../../journal/domain/repositories/journal_repository.dart';
import '../../domain/entities/insights_entity.dart';
import '../../domain/repositories/insights_repository.dart';

@LazySingleton(as: InsightsRepository)
class InsightsRepositoryImpl implements InsightsRepository {
  final JournalRepository _journalRepository;

  InsightsRepositoryImpl(this._journalRepository);

  @override
  Future<(Failure?, InsightsEntity?)> getInsights() async {
    try {
      final (failure, entries) = await _journalRepository.getEntries();
      if (failure != null) return (failure, null);
      if (entries == null) return (null, InsightsEntity.empty());

      int totalWords = 0;
      final Map<String, int> moodDist = {};

      for (final entry in entries) {
        // Simple word count
        final words = entry.content.trim().split(RegExp(r'\s+')).length;
        totalWords += words;

        final moodKey = entry.mood.name;
        moodDist[moodKey] = (moodDist[moodKey] ?? 0) + 1;
      }

      final insights = InsightsEntity(
        totalEntries: entries.length,
        totalWords: totalWords,
        moodDistribution: moodDist,
      );

      return (null, insights);
    } catch (e) {
      return (StorageFailure(message: e.toString()), null);
    }
  }
}
