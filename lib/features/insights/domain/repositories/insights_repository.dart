import '../../../../core/errors/failures.dart';
import '../entities/insights_entity.dart';

abstract class InsightsRepository {
  Future<(Failure?, InsightsEntity?)> getInsights();
}
