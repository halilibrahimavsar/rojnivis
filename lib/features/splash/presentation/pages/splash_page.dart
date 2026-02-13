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

    final authState = context.read<AuthBloc>().state;
    final localAuthRepo = getIt<LocalAuthRepository>();
    
    // Check if either biometric or PIN is enabled
    final isBiometricEnabled = await localAuthRepo.isBiometricEnabled();
    final isPinSet = await localAuthRepo.isPinSet();
    final isLocalAuthEnabled = isBiometricEnabled || isPinSet;

    // Small delay to ensure smooth transition if animation *just* finished
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    if (authState is AuthenticatedState) {
      if (isLocalAuthEnabled) {
        // User has local auth enabled, but since this is Splash,
        // we might want to let the LocalAuthSecurityLayer handle the lock screen?
        // HOWEVER, LocalAuthSecurityLayer usually wraps the *child* of the router
        // or the specific protected pages.
        // If we route to '/home', the layer should kick in.
        // Let's route to home and let the security layer intercept if configured globally.
        // OR if we want an explicit "Unlock" screen separate from the layer:
        
        // For now, standard behavior: Auth'd -> Home.
        // The LocalAuthSecurityLayer (if wrapping MaterialApp builder) will show logic 
        // if user has just opened app.
        context.go('/home');
      } else {
        context.go('/home');
      }
    } else {
      // Not authenticated -> Login
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
