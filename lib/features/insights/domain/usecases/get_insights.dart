import 'package:injectable/injectable.dart';
import '../../../../core/errors/failures.dart';
import '../entities/insights_entity.dart';
import '../repositories/insights_repository.dart';

@lazySingleton
class GetInsights {
  final InsightsRepository _repository;

  GetInsights(this._repository);

  Future<(Failure?, InsightsEntity?)> call() => _repository.getInsights();
}
