part of 'splash_bloc.dart';

abstract class SplashEvent extends Equatable {
  const SplashEvent();

  @override
  List<Object?> get props => [];
}

class InitializeSplash extends SplashEvent {
  const InitializeSplash();
}

class SplashAnimationComplete extends SplashEvent {
  final int retryCount;
  const SplashAnimationComplete({this.retryCount = 0});

  @override
  List<Object?> get props => [retryCount];
}
