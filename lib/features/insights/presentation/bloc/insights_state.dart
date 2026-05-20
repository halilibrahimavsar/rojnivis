part of 'insights_bloc.dart';

abstract class InsightsState extends Equatable {
  const InsightsState();

  @override
  List<Object?> get props => [];
}

class InsightsInitial extends InsightsState {
  const InsightsInitial();
}

class InsightsLoading extends InsightsState {
  const InsightsLoading();
}

class InsightsLoaded extends InsightsState {
  final InsightsEntity insights;

  const InsightsLoaded({required this.insights});

  @override
  List<Object?> get props => [insights];
}

class InsightsError extends InsightsState {
  final String message;

  const InsightsError({required this.message});

  @override
  List<Object?> get props => [message];
}
