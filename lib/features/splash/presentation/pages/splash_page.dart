import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remote_auth_module/remote_auth_module.dart';
import 'package:unified_flutter_features/features/local_auth/data/local_auth_repository.dart';

import '../../../../core/widgets/themed_paper.dart';
import '../../../../di/injection.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isAnimationComplete = false;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic),
    );

    _startDisplaySequence();
  }

  Future<void> _startDisplaySequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    await _fadeController.forward();

    // Hold the splash logo for a second before allowing navigation
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isAnimationComplete = true;
    });

    _checkAndNavigate();
  }

  void _checkAndNavigate() async {
    if (!_isAnimationComplete || !mounted) return;

    final authState = context.read<AuthBloc>().state;
    // Don't navigate while still initializing
    if (authState is AuthInitialState || authState is AuthLoadingState) return;

    final localAuthRepo = getIt<LocalAuthRepository>();

    final isBiometricEnabled = await localAuthRepo.isBiometricEnabled();
    final isPinSet = await localAuthRepo.isPinSet();
    final isLocalAuthEnabled = isBiometricEnabled || isPinSet;

    if (!mounted) return;

    if (authState is AuthenticatedState) {
      if (isLocalAuthEnabled) {
        context.go('/home');
      } else {
        context.go('/home');
      }
    } else if (authState is UnauthenticatedState ||
        authState is AuthErrorState) {
      context.go('/public');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (_isAnimationComplete) {
            _checkAndNavigate();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ThemedBackdrop(applyPageStudio: true, opacity: 1.0),
            Center(
              child: AnimatedBuilder(
                animation: _fadeController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.auto_stories_rounded,
                            size: 80,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'ROJNIVIS',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 8.0,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Your Personal Journal',
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium?.copyWith(
                              letterSpacing: 2.0,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
