import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'canvas_controller.dart';

/// Canvas operating modes
enum CanvasMode {
  select, // Select and move nodes
  pan, // Pan the canvas
  draw, // Draw connections
  erase, // Erase nodes/connections
}

/// Professional canvas toolbar with mode selection and common actions
class CanvasToolbar extends StatelessWidget {
  const CanvasToolbar({
    super.key,
    required this.controller,
    required this.mode,
    required this.onModeChanged,
    required this.showGrid,
    required this.onToggleGrid,
    required this.snapToGrid,
    required this.onToggleSnap,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onResetZoom,
    required this.onCenter,
    this.onAutoLayout,
    this.onUndo,
    this.onRedo,
  });

  final CanvasController controller;
  final CanvasMode mode;
  final ValueChanged<CanvasMode> onModeChanged;
  final bool showGrid;
  final VoidCallback onToggleGrid;
  final bool snapToGrid;
  final VoidCallback onToggleSnap;
  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onResetZoom;
  final VoidCallback onCenter;
  final VoidCallback? onAutoLayout;
  final VoidCallback? onUndo;
  final VoidCallback? onRedo;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface.withOpacity(0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Mode selection
                    _ToolGroup(
                      children: [
                        _ToolButton(
                          icon: Icons.mouse_outlined,
                          label: 'select'.tr(),
                          isActive: mode == CanvasMode.select,
                          onPressed: () => onModeChanged(CanvasMode.select),
                          tooltip: 'select_mode'.tr(),
                        ),
                        _ToolButton(
                          icon: Icons.pan_tool_outlined,
                          label: 'pan'.tr(),
                          isActive: mode == CanvasMode.pan,
                          onPressed: () => onModeChanged(CanvasMode.pan),
                          tooltip: 'pan_mode'.tr(),
                        ),
                      ],
                    ),

                    _Divider(colorScheme: colorScheme),

                    // Undo/Redo
                    _ToolGroup(
                      children: [
                        _ToolButton(
                          icon: Icons.undo,
                          onPressed: onUndo,
                          tooltip: 'undo'.tr(),
                        ),
                        _ToolButton(
                          icon: Icons.redo,
                          onPressed: onRedo,
                          tooltip: 'redo'.tr(),
                        ),
                      ],
                    ),

                    _Divider(colorScheme: colorScheme),

                    // Grid options
                    _ToolGroup(
                      children: [
                        _ToolButton(
                          icon: Icons.grid_4x4_outlined,
                          isActive: showGrid,
                          onPressed: onToggleGrid,
                          tooltip: 'toggle_grid'.tr(),
                        ),
                        _ToolButton(
                          icon: Icons.grid_on_outlined,
                          isActive: snapToGrid,
                          onPressed: onToggleSnap,
                          tooltip: 'snap_to_grid'.tr(),
                        ),
                      ],
                    ),

                    _Divider(colorScheme: colorScheme),

                    // View controls
                    _ToolGroup(
                      children: [
                        _ToolButton(
                          icon: Icons.center_focus_strong,
                          onPressed: onCenter,
                          tooltip: 'center_on_content'.tr(),
                        ),
                      ],
                    ),

                    if (onAutoLayout != null) ...[
                      _Divider(colorScheme: colorScheme),

                      _ToolGroup(
                        children: [
                          _ToolButton(
                            icon: Icons.auto_fix_high,
                            label: 'auto_layout'.tr(),
                            onPressed: onAutoLayout,
                            tooltip: 'auto_layout'.tr(),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            // Modern scroll indicators
            IgnorePointer(child: _ScrollIndicators(colorScheme: colorScheme)),
          ],
        ),
      ),
    );
  }
}

class _ToolGroup extends StatelessWidget {
  const _ToolGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: children);
  }
}

class _ToolButton extends StatelessWidget {
  const _ToolButton({
    required this.icon,
    this.label,
    this.isActive = false,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final String? label;
  final bool isActive;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final button = Material(
      color: isActive ? colorScheme.primaryContainer : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: label != null ? 12 : 10,
            vertical: 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    onPressed == null
                        ? colorScheme.onSurface.withOpacity(0.3)
                        : isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurface,
              ),
              if (label != null) ...[
                const SizedBox(width: 6),
                Text(
                  label!,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color:
                        onPressed == null
                            ? colorScheme.onSurface.withOpacity(0.3)
                            : isActive
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }

    return button;
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: colorScheme.outlineVariant,
    );
  }
}

/// Modern scroll indicators with subtle fade and chevron icons
class _ScrollIndicators extends StatelessWidget {
  const _ScrollIndicators({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left indicator
        Expanded(child: _buildIndicator(isLeft: true)),
        const Spacer(),
        // Right indicator
        Expanded(child: _buildIndicator(isLeft: false)),
      ],
    );
  }

  Widget _buildIndicator({required bool isLeft}) {
    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        width: 20, // Geçişin daha belirgin olması için genişliği biraz artırdım
        height: 48,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Başlangıç noktası kenardan başlar
            begin: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            // Bitiş noktası içeriye doğrudur
            end: isLeft ? Alignment.centerRight : Alignment.centerLeft,

            colors: [
              // Kenar tarafı daha belirgin (opak)
              colorScheme.primary.withValues(alpha: 0.3),
              // İç tarafa doğru tamamen kaybolur (şeffaf)
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
