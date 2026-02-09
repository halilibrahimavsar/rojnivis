import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/models/mind_map_node.dart';
import '../bloc/mind_map_bloc.dart';
import '../widgets/widgets.dart';
import 'mind_map_list_view.dart';
import 'mind_map_canvas_view.dart';

class MindMapPage extends StatelessWidget {
  const MindMapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('mind_maps'.tr()),
        actions: [
          FilledButton.tonalIcon(
            onPressed: () => _showCreateMindMapDialog(context),
            icon: const Icon(Icons.add),
            label: Text('create_mind_map'.tr()),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: const MindMapBody(),
    );
  }

  void _showCreateMindMapDialog(BuildContext context) {
    showDialog<String>(
      context: context,
      builder:
          (context) => MindMapNodeEditor(
            title: 'create_mind_map'.tr(),
            buttonText: 'create'.tr(),
            initialText: '',
            onSubmit: (label) {
              final newNode = MindMapNode.create(label: label, x: 150, y: 150);
              context.read<MindMapBloc>().add(SaveMindMap(newNode));
            },
          ),
    );
  }
}

class MindMapBody extends StatefulWidget {
  const MindMapBody({super.key});

  @override
  State<MindMapBody> createState() => _MindMapBodyState();
}

class _MindMapBodyState extends State<MindMapBody> {
  bool _isCanvasView = false;

  @override
  Widget build(BuildContext context) {
    return BlocListener<MindMapBloc, MindMapState>(
      listener: (context, state) {
        if (state is MindMapError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      },
      child: BlocBuilder<MindMapBloc, MindMapState>(
        builder: (context, state) {
          if (state is MindMapLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MindMapLoaded) {
            return MindMapContent(
              mindMaps: state.mindMaps,
              selectedMindMap: state.selectedMindMap,
              isCanvasView: _isCanvasView,
              onViewChanged: (isCanvas) {
                setState(() {
                  _isCanvasView = isCanvas;
                });
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class MindMapContent extends StatelessWidget {
  final List<MindMapNode> mindMaps;
  final MindMapNode? selectedMindMap;
  final bool isCanvasView;
  final Function(bool) onViewChanged;

  const MindMapContent({
    super.key,
    required this.mindMaps,
    this.selectedMindMap,
    required this.isCanvasView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (mindMaps.isEmpty) {
      return EmptyStateWidget(
        icon: Icons.account_tree_outlined,
        title: 'no_mind_maps'.tr(),
        subtitle: 'create_first_mind_map_hint'.tr(),
        buttonText: 'create_first_mind_map'.tr(),
        onButtonPressed: () => _showCreateMindMapDialogForEmptyState(context),
      );
    }

    final currentMindMap = selectedMindMap ?? mindMaps.first;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FilterChip(
                label: Row(
                  children: [
                    const Icon(Icons.view_list, size: 18),
                    const SizedBox(width: 6),
                    Text('list_view'.tr()),
                  ],
                ),
                selected: !isCanvasView,
                onSelected: (_) {
                  onViewChanged(false);
                },
              ),
              const SizedBox(width: 16),
              FilterChip(
                label: Row(
                  children: [
                    const Icon(Icons.grid_view, size: 18),
                    const SizedBox(width: 6),
                    Text('canvas_view'.tr()),
                  ],
                ),
                selected: isCanvasView,
                onSelected: (_) {
                  onViewChanged(true);
                },
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          child: Row(
            children: [
              Expanded(
                child: DropdownButton<MindMapNode>(
                  value: currentMindMap,
                  isExpanded: true,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  items:
                      mindMaps.map((node) {
                        return DropdownMenuItem<MindMapNode>(
                          value: node,
                          child: Row(
                            children: [
                              Icon(Icons.circle, color: node.color, size: 12),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  node.label,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  onChanged: (MindMapNode? newValue) {
                    if (newValue != null) {
                      context.read<MindMapBloc>().add(SelectMindMap(newValue));
                    }
                  },
                ),
              ),
              if (mindMaps.length > 1)
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed:
                      () => _showDeleteMindMapDialog(context, currentMindMap),
                  tooltip: 'delete_mind_map'.tr(),
                ),
            ],
          ),
        ),
        Expanded(
          child:
              isCanvasView
                  ? MindMapCanvasView(
                    mindMap: currentMindMap,
                    onNodeUpdated: (updatedNode) {
                      context.read<MindMapBloc>().add(SaveMindMap(updatedNode));
                    },
                  )
                  : MindMapListView(
                    mindMap: currentMindMap,
                    onNodeUpdated: (updatedNode) {
                      context.read<MindMapBloc>().add(SaveMindMap(updatedNode));
                    },
                  ),
        ),
      ],
    );
  }

  void _showCreateMindMapDialogForEmptyState(BuildContext context) {
    showDialog<String>(
      context: context,
      builder:
          (context) => MindMapNodeEditor(
            title: 'create_mind_map'.tr(),
            buttonText: 'create'.tr(),
            initialText: '',
            onSubmit: (label) {
              final newNode = MindMapNode.create(label: label, x: 150, y: 150);
              context.read<MindMapBloc>().add(SaveMindMap(newNode));
            },
          ),
    );
  }

  void _showDeleteMindMapDialog(BuildContext context, MindMapNode mindMap) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_mind_map'.tr()),
            content: Text('delete_mind_map_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.read<MindMapBloc>().add(DeleteMindMap(mindMap.id));
                },
                child: Text(
                  'delete'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );
  }
}
