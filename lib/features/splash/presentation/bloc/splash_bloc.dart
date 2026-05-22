import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';
import 'package:remote_auth_module/remote_auth_module.dart';

part 'splash_event.dart';
part 'splash_state.dart';

@injectable
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  final AuthBloc _authBloc;
  StreamSubscription? _authSubscription;

  SplashBloc(this._authBloc) : super(const SplashInitial()) {
    on<InitializeSplash>(_onInitialize);
    on<SplashAnimationComplete>(_onAnimationComplete);

    _authSubscription = _authBloc.stream.listen((authState) {
      if (state is SplashDisplaying) {
        add(const SplashAnimationComplete());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription?.cancel();
    return super.close();
  }

  Future<void> _onInitialize(
    InitializeSplash event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashDisplaying());
  }

  Future<void> _onAnimationComplete(
    SplashAnimationComplete event,
    Emitter<SplashState> emit,
  ) async {
    // If AuthBloc is still initializing, we might need to wait or check again.
    final authState = _authBloc.state;

    if (authState is AuthenticatedState) {
      final rememberMe = await RememberMeService().load();
      if (!rememberMe) {
        _authBloc.add(const SignOutEvent());
        emit(const SplashNavigating(SplashNavigationTarget.public));
        return;
      }
      emit(const SplashNavigating(SplashNavigationTarget.home));
    } else if (authState is UnauthenticatedState ||
        authState is AuthErrorState) {
      emit(const SplashNavigating(SplashNavigationTarget.public));
    } else {
      // AuthBloc is still initializing.
      // We removed the 500ms polling loop!
      // The _authSubscription will automatically trigger this event again the exact millisecond AuthBloc is ready.
    }
  }
}
