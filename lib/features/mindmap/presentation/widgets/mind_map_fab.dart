import 'package:flutter/material.dart';

class MindMapFab extends StatelessWidget {
  final VoidCallback onPressed;
  final String tooltip;
  final IconData icon;
  final String label;

  const MindMapFab({
    super.key,
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}
