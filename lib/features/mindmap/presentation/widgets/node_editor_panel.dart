import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';

/// Professional node editor panel for editing selected nodes
class NodeEditorPanel extends StatelessWidget {
  const NodeEditorPanel({
    super.key,
    required this.node,
    required this.onUpdate,
    required this.onAddChild,
    required this.onDelete,
    required this.onClose,
  });

  final MindMapNode node;
  final Function(MindMapNode) onUpdate;
  final VoidCallback onAddChild;
  final VoidCallback onDelete;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
            child: Row(
              children: [
                // Color indicator
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: node.color,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: node.color.withOpacity(0.3),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Node info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        node.label,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${node.children.length} ${'children'.tr()}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),

                // Close button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  tooltip: 'close'.tr(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ActionButton(
                    icon: Icons.add_circle_outline,
                    label: 'add_child'.tr(),
                    color: colorScheme.primary,
                    onPressed: onAddChild,
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.edit_outlined,
                    label: 'edit'.tr(),
                    color: colorScheme.secondary,
                    onPressed: () => _showEditDialog(context),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.palette_outlined,
                    label: 'color'.tr(),
                    color: colorScheme.tertiary,
                    onPressed: () => _showColorPicker(context),
                  ),
                  const SizedBox(width: 8),
                  _ActionButton(
                    icon: Icons.delete_outline,
                    label: 'delete'.tr(),
                    color: colorScheme.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: node.label);

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('edit_node'.tr()),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'node_label'.tr(),
                border: const OutlineInputBorder(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  final newLabel = controller.text.trim();
                  if (newLabel.isNotEmpty) {
                    onUpdate(node.copyWith(label: newLabel));
                    Navigator.pop(ctx);
                  }
                },
                child: Text('save'.tr()),
              ),
            ],
          ),
    );
  }

  void _showColorPicker(BuildContext context) {
    const colors = [
      Color(0xFF2196F3), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFF44336), // Red
      Color(0xFFFF9800), // Orange
      Color(0xFF9C27B0), // Purple
      Color(0xFFE91E63), // Pink
      Color(0xFF00BCD4), // Cyan
      Color(0xFFFFEB3B), // Yellow
      Color(0xFF795548), // Brown
      Color(0xFF607D8B), // Blue Grey
    ];

    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('choose_color'.tr()),
            content: Wrap(
              spacing: 12,
              runSpacing: 12,
              children:
                  colors.map((color) {
                    final isSelected = color.value == node.colorValue;
                    return InkWell(
                      onTap: () {
                        onUpdate(node.copyWith(colorValue: color.value));
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.4),
                              blurRadius: isSelected ? 8 : 4,
                              spreadRadius: isSelected ? 2 : 0,
                            ),
                          ],
                        ),
                        child:
                            isSelected
                                ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 24,
                                )
                                : null,
                      ),
                    );
                  }).toList(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr()),
              ),
            ],
          ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
