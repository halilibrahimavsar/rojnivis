import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/insights_entity.dart';
import '../../domain/usecases/get_insights.dart';

part 'insights_event.dart';
part 'insights_state.dart';

@injectable
class InsightsBloc extends Bloc<InsightsEvent, InsightsState> {
  final GetInsights _getInsights;

  InsightsBloc(this._getInsights) : super(const InsightsInitial()) {
    on<LoadInsights>(_onLoad);
  }

  Future<void> _onLoad(LoadInsights event, Emitter<InsightsState> emit) async {
    emit(const InsightsLoading());
    final (failure, insights) = await _getInsights();

    if (failure != null || insights == null) {
      emit(InsightsError(message: failure?.message ?? 'Unknown error'));
      return;
    }

    emit(InsightsLoaded(insights: insights));
  }
}
