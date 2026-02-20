import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'themed_paper.dart';
import 'glass_overlays.dart';
import 'interactive_top_bar.dart';

class AppLayout extends StatefulWidget {
  const AppLayout({super.key, required this.child});
  final Widget child;

  @override
  State<AppLayout> createState() => _AppLayoutState();
}

class _AppLayoutState extends State<AppLayout> {
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home/settings')) return 4;
    if (location.startsWith('/home/calendar')) return 3;
    if (location.startsWith('/home/categories')) return 1;
    // Default to journal
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/home/categories');
        break;
      case 2:
        context.push('/home/add-entry');
        break;
      case 3:
        context.go('/home/calendar');
        break;
      case 4:
        context.go('/home/settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Global backdrop
          ThemedPaper(lined: true, applyPageStudio: true, child: widget.child),

          // Persistent Top Overlays
          const Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(child: InteractiveTopBar()),
          ),

          // Persistent Bottom Navigation Dock
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: GlassNavigationBar(
              currentIndex: _calculateSelectedIndex(context),
              onTap: (index) => _onItemTapped(index, context),
            ),
          ),
        ],
      ),
    );
  }
}
