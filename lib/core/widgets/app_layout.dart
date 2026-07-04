import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'themed_paper.dart';
import 'glass_overlays.dart';
import 'interactive_top_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rojnivis/features/reminders/domain/entities/reminder.dart';
import 'package:rojnivis/features/reminders/presentation/bloc/reminders/reminders_bloc.dart';
import 'package:rojnivis/features/reminders/presentation/bloc/reminders/reminders_event.dart';
import 'package:rojnivis/features/reminders/presentation/widgets/add_reminder_dialog.dart';

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
    if (location.startsWith('/home/reminders')) return 3;
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
        _showAddMenu(context);
        break;
      case 3:
        context.go('/home/reminders');
        break;
      case 4:
        context.go('/home/settings');
        break;
    }
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bottomSheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.book, color: Colors.blueAccent),
                  title: const Text(
                    'Günlük Ekle',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(bottomSheetContext);
                    context.push('/home/add-entry');
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm, color: Colors.orangeAccent),
                  title: const Text(
                    'Hatırlatıcı Ekle',
                    style: TextStyle(color: Colors.white),
                  ),
                  onTap: () async {
                    Navigator.pop(bottomSheetContext);
                    final reminder = await showDialog<Reminder>(
                      context: context,
                      barrierColor: Colors.black.withValues(alpha: 0.6),
                      builder:
                          (context) =>
                              AddReminderDialog(selectedDate: DateTime.now()),
                    );
                    if (reminder != null && context.mounted) {
                      context.read<RemindersBloc>().add(
                        AddReminderToList(reminder),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
