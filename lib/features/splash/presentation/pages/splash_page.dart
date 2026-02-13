import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';

import '../../../../di/injection.dart';
import '../widgets/book_opening_animation.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  bool _isAnimationComplete = false;
  
  // To verify auth status
  // We'll assume the AuthBloc is already initialized in main.dart
  // and has fired an event. We just need to check its current state.
  
  void _checkAndNavigate() async {
    if (!_isAnimationComplete) return;
    if (!mounted) return;

    final authState = context.read<AuthBloc>().state;
    // Don't navigate while still initializing
    if (authState is AuthInitialState || authState is AuthLoadingState) return;

    final localAuthRepo = getIt<LocalAuthRepository>();
    
    // Check if either biometric or PIN is enabled
    final isBiometricEnabled = await localAuthRepo.isBiometricEnabled();
    final isPinSet = await localAuthRepo.isPinSet();
    final isLocalAuthEnabled = isBiometricEnabled || isPinSet;

    // Small delay to ensure smooth transition
    if (!mounted) return;
    // We can remove the arbitrary delay or keep it minimal if we want to show the full book for a split second
    // await Future.delayed(const Duration(milliseconds: 300)); 

    if (authState is AuthenticatedState) {
        if (isLocalAuthEnabled) {
             context.go('/home');
        } else {
             context.go('/home');
        }
    } else if (authState is UnauthenticatedState) {
       context.go('/public');
    }
    // If AuthErrorState, we might want to go to public or show error. 
    // Usually unauthenticated is safer.
    else if (authState is AuthErrorState) {
       context.go('/public');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          // If auth state changes *during* animation (e.g. initial load finishes),
          // we just wait for animation to complete. _checkAndNavigate checks the *current* state.
          if (_isAnimationComplete) {
            _checkAndNavigate();
          }
        },
        child: BookOpeningAnimation(
          onAnimationComplete: () {
            setState(() {
              _isAnimationComplete = true;
            });
            _checkAndNavigate();
          },
        ),
      ),
    );
  }
}
