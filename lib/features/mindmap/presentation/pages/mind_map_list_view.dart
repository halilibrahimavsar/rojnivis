import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';

class MindMapListView extends StatefulWidget {
  final MindMapNode mindMap;
  final Function(MindMapNode) onNodeUpdated;

  const MindMapListView({
    super.key,
    required this.mindMap,
    required this.onNodeUpdated,
  });

  @override
  State<MindMapListView> createState() => _MindMapListViewState();
}

class _MindMapListViewState extends State<MindMapListView> {
  void _addChildNode(String parentId) {
    final TextEditingController controller = TextEditingController();
    showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('add_node'.tr()),
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
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    final newNode = MindMapNode.create(
                      label: controller.text.trim(),
                      parentId: parentId,
                    );
                    final updatedMap = widget.mindMap.addChild(
                      parentId,
                      newNode,
                    );
                    widget.onNodeUpdated(updatedMap);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('add'.tr()),
              ),
            ],
          ),
    );
  }

  void _editNode(MindMapNode node) {
    final controller = TextEditingController(text: node.label);
    showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
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
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  if (controller.text.trim().isNotEmpty) {
                    final updatedMap = widget.mindMap.updateNode(
                      node.id,
                      (n) => n.copyWith(label: controller.text.trim()),
                    );
                    widget.onNodeUpdated(updatedMap);
                    Navigator.of(context).pop();
                  }
                },
                child: Text('save'.tr()),
              ),
            ],
          ),
    );
  }

  void _deleteNode(String nodeId) {
    showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_node'.tr()),
            content: Text('delete_node_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('delete'.tr()),
              ),
            ],
          ),
    ).then((shouldDelete) {
      if (shouldDelete == true) {
        final updatedMap = widget.mindMap.removeChild(nodeId);
        widget.onNodeUpdated(updatedMap);
      }
    });
  }

  Widget _buildNodeActions(MindMapNode node) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.add_circle_outline, size: 20),
          onPressed: () => _addChildNode(node.id),
          tooltip: 'add_child'.tr(),
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          onPressed: () => _editNode(node),
          tooltip: 'edit'.tr(),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, size: 20),
          onPressed: () => _deleteNode(node.id),
          tooltip: 'delete'.tr(),
        ),
      ],
    );
  }

  Widget _buildNodeTile(MindMapNode node, {bool isRoot = false}) {
    return ExpansionTile(
      leading: Icon(Icons.brightness_1, color: node.color, size: 10),
      title: Text(node.label, style: Theme.of(context).textTheme.titleMedium),
      trailing: _buildNodeActions(node),
      children:
          node.children.isEmpty
              ? [
                Padding(
                  padding: const EdgeInsets.only(left: 40),
                  child: ListTile(
                    leading: const Icon(Icons.subdirectory_arrow_right),
                    title: Text(
                      'no_sub_nodes'.tr(),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ]
              : node.children.map((child) {
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildNodeTile(child),
                );
              }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 420;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.mindMap.label,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    '${widget.mindMap.children.length} ${'nodes'.tr()}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              );

              final actions = Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _addChildNode(widget.mindMap.id),
                    icon: const Icon(Icons.add),
                    label: Text('add_root_node'.tr()),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _editNode(widget.mindMap),
                    icon: const Icon(Icons.edit),
                    tooltip: 'edit_root'.tr(),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [titleBlock, const SizedBox(height: 12), actions],
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 12),
                  actions,
                ],
              );
            },
          ),
        ),
        const Divider(),
        Expanded(
          child:
              widget.mindMap.children.isEmpty
                  ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.account_tree_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'no_nodes_yet'.tr(),
                          style: Theme.of(
                            context,
                          ).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        FilledButton.tonal(
                          onPressed: () => _addChildNode(widget.mindMap.id),
                          child: Text('add_first_node'.tr()),
                        ),
                      ],
                    ),
                  )
                  : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    children:
                        widget.mindMap.children.map((child) {
                          return _buildNodeTile(child, isRoot: true);
                        }).toList(),
                  ),
        ),
      ],
    );
  }
}
