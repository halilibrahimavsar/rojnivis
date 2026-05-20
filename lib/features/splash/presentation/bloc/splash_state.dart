part of 'splash_bloc.dart';

enum SplashNavigationTarget { home, public, none }

abstract class SplashState extends Equatable {
  const SplashState();

  @override
  List<Object?> get props => [];
}

class SplashInitial extends SplashState {
  const SplashInitial();
}

class SplashDisplaying extends SplashState {
  const SplashDisplaying();
}

class SplashNavigating extends SplashState {
  final SplashNavigationTarget target;

  const SplashNavigating(this.target);

  @override
  List<Object?> get props => [target];
}
