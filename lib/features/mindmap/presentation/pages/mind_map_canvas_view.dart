import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';
import '../widgets/widgets.dart';
import '../widgets/mind_map_minimap.dart';
import '../widgets/grid_painter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/old_page_theme.dart';

class MindMapCanvasView extends StatefulWidget {
  final MindMapNode mindMap;
  final Function(MindMapNode) onNodeUpdated;

  const MindMapCanvasView({
    super.key,
    required this.mindMap,
    required this.onNodeUpdated,
  });

  @override
  State<MindMapCanvasView> createState() => _MindMapCanvasViewState();
}

class _MindMapCanvasViewState extends State<MindMapCanvasView>
    with TickerProviderStateMixin {
  final TransformationController _transformController =
      TransformationController();

  MindMapNode? _selectedNode;
  MindMapNode? _draggingNode;

  double _currentScale = 1.0;
  bool _isQuickEditMode = false;
  bool _showMinimap = true;
  bool _simpleMode = false;

  // Entrance animation
  late final AnimationController _entranceController;
  late final Animation<double> _entranceAnimation;

  static const double _nodeWidth = AppMindMap.nodeWidth;
  static const double _nodeHeight = AppMindMap.nodeHeight;
  static const double _levelSpacing = AppMindMap.levelSpacing;
  static const double _siblingSpacing = AppMindMap.siblingSpacing;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _entranceAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutBack,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnNodes();
      _entranceController.forward();
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  void _centerOnNodes() {
    final nodes = _getAllNodes();
    if (nodes.isEmpty) return;

    final bounds = _calculateBounds(nodes);
    final centerX = bounds.center.dx;
    final centerY = bounds.center.dy;

    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final targetX = size.width / 2 - centerX;
    final targetY = size.height / 2 - centerY;

    setState(() => _currentScale = 1.0);
    _transformController.value =
        Matrix4.identity()
          ..translate(targetX, targetY)
          ..scale(1.0);
  }

  void _zoom(double delta) {
    final newScale = (_currentScale + delta).clamp(0.3, 3.0);
    if (newScale == _currentScale) return;

    setState(() => _currentScale = newScale);

    final matrix = _transformController.value;
    final currentScale = matrix.getMaxScaleOnAxis();
    final scaleDelta = newScale / currentScale;

    _transformController.value = matrix..scale(scaleDelta);
  }

  Rect _calculateBounds(List<MindMapNode> nodes) {
    if (nodes.isEmpty) return Rect.zero;

    double minX = nodes.first.x;
    double maxX = nodes.first.x + _nodeWidth;
    double minY = nodes.first.y;
    double maxY = nodes.first.y + _nodeHeight;

    for (final node in nodes) {
      minX = math.min(minX, node.x);
      maxX = math.max(maxX, node.x + _nodeWidth);
      minY = math.min(minY, node.y);
      maxY = math.max(maxY, node.y + _nodeHeight);
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  List<MindMapNode> _getAllNodes() {
    final nodes = <MindMapNode>[];
    void collect(MindMapNode n) {
      nodes.add(n);
      for (final child in n.children) {
        collect(child);
      }
    }

    collect(widget.mindMap);
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final nodes = _getAllNodes();

    return Stack(
      children: [
        // Background
        if (_simpleMode)
          Positioned.fill(
            child: CustomPaint(
              painter: GridPainter(
                colorScheme: colorScheme,
                scale: _currentScale,
                offset: Offset(
                  _transformController.value.getTranslation().x,
                  _transformController.value.getTranslation().y,
                ),
              ),
            ),
          )
        else
          const OldPageBackground(showStains: true),

        InteractiveViewer(
          transformationController: _transformController,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          minScale: 0.3,
          maxScale: 3.0,
          panEnabled: _draggingNode == null,
          onInteractionUpdate: (details) {
            setState(
              () =>
                  _currentScale =
                      _transformController.value.getMaxScaleOnAxis(),
            );
          },
          child: SizedBox(
            width: 10000,
            height: 10000,
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () => setState(() => _selectedNode = null),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CustomPaint(
                    size: const Size(10000, 10000),
                    painter: ConnectionsPainter(
                      root: widget.mindMap,
                      colorScheme: colorScheme,
                    ),
                  ),
                  // Animated node entrance
                  ...nodes.asMap().entries.map((entry) {
                    final index = entry.key;
                    final node = entry.value;

                    return Positioned(
                      left: node.x,
                      top: node.y,
                      child: AnimatedBuilder(
                        animation: _entranceAnimation,
                        builder: (context, child) {
                          final stagger = (index * 0.08).clamp(0.0, 0.6);
                          final progress = ((_entranceAnimation.value -
                                      stagger) /
                                  (1.0 - stagger))
                              .clamp(0.0, 1.0);
                          return Transform.scale(
                            scale: progress,
                            child: Opacity(opacity: progress, child: child),
                          );
                        },
                        child: _buildNodeInteractive(node, colorScheme),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
        _buildControls(colorScheme),
        if (_selectedNode != null) _buildEditor(colorScheme),

        // Minimap
        if (_showMinimap)
          MindMapMinimap(
            root: widget.mindMap,
            transformController: _transformController,
          ),
      ],
    );
  }

  Widget _buildNodeInteractive(MindMapNode node, ColorScheme colorScheme) {
    final isSelected = _selectedNode?.id == node.id;

    return DragTarget<MindMapNode>(
      onWillAcceptWithDetails: (details) {
        final dragged = details.data;
        // Cannot drop on itself or onto its own descendants
        if (dragged.id == node.id) return false;
        return !_isDescendantOf(node, dragged.id);
      },
      onAcceptWithDetails: (details) {
        final dragged = details.data;
        _reorganizeNode(dragged, node);
      },
      builder: (context, candidateData, rejectedData) {
        final isTarget = candidateData.isNotEmpty;
        return GestureDetector(
          onTap: () => setState(() => _selectedNode = isSelected ? null : node),
          onPanUpdate: (d) {
            if (_draggingNode != node) return;
            final delta = d.delta;
            final updated = widget.mindMap.updateNode(
              node.id,
              (n) => n.copyWith(x: n.x + delta.dx, y: n.y + delta.dy),
            );
            widget.onNodeUpdated(updated);
          },
          child: Draggable<MindMapNode>(
            data: node,
            feedback: Material(
              color: Colors.transparent,
              child: _buildNodeContent(
                node,
                colorScheme,
                isSelected: true,
                isDragging: true,
              ),
            ),
            childWhenDragging: Opacity(
              opacity: 0.3,
              child: _buildNodeContent(
                node,
                colorScheme,
                isSelected: isSelected,
              ),
            ),
            onDragStarted: () => setState(() => _draggingNode = node),
            onDragEnd: (details) {
              setState(() => _draggingNode = null);
              if (details.wasAccepted) {
                return; // Reorganized, position handled by reorganization
              }

              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPos = renderBox.globalToLocal(details.offset);

              // Adjust for transformation
              final matrix = _transformController.value.clone()..invert();
              final transformedOffset = MatrixUtils.transformPoint(
                matrix,
                localPos,
              );

              final updated = widget.mindMap.updateNode(
                node.id,
                (n) => n.copyWith(
                  x: transformedOffset.dx,
                  y: transformedOffset.dy,
                ),
              );
              widget.onNodeUpdated(updated);
            },
            child: _buildNodeContent(
              node,
              colorScheme,
              isSelected: isSelected,
              isTarget: isTarget,
            ),
          ),
        );
      },
    );
  }

  bool _isDescendantOf(MindMapNode parent, String targetId) {
    for (final child in parent.children) {
      if (child.id == targetId) return true;
      if (_isDescendantOf(child, targetId)) return true;
    }
    return false;
  }

  void _reorganizeNode(MindMapNode dragged, MindMapNode newParent) {
    // 1. Remove from current parent
    var updatedRoot = widget.mindMap.removeChild(dragged.id);
    // 2. Add to new parent
    updatedRoot = updatedRoot.addChild(newParent.id, dragged);

    widget.onNodeUpdated(updatedRoot);
  }

  Widget _buildNodeContent(
    MindMapNode node,
    ColorScheme colorScheme, {
    bool isSelected = false,
    bool isDragging = false,
    bool isTarget = false,
  }) {
    final isRoot = node.id == widget.mindMap.id;

    // Shape decoration
    final decoration =
        node.effectiveUseGradient
            ? BoxDecoration(
              gradient: LinearGradient(
                colors: [node.color, node.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: _getBorderRadius(node.effectiveShape),
              boxShadow: _getShadows(isSelected || isTarget),
              border:
                  (isSelected || isTarget)
                      ? Border.all(
                        color:
                            isTarget
                                ? Colors.greenAccent
                                : Colors.white.withValues(alpha: 0.5),
                        width: isTarget ? 3 : 2,
                      )
                      : null,
            )
            : BoxDecoration(
              color: isRoot ? node.color.withValues(alpha: 0.15) : Colors.white,
              borderRadius: _getBorderRadius(node.effectiveShape),
              border: Border.all(
                color:
                    isTarget
                        ? Colors.greenAccent
                        : (isSelected ? node.color : Colors.grey.shade300),
                width: (isSelected || isTarget) ? (isTarget ? 3.5 : 2.5) : 1,
              ),
              boxShadow: _getShadows(isSelected || isTarget),
            );

    return AnimatedScale(
      scale: isSelected ? 1.05 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutBack,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _nodeWidth,
        height: _nodeHeight,
        decoration: decoration,
        child: Material(
          color: Colors.transparent,
          borderRadius: _getBorderRadius(node.effectiveShape),
          child: InkWell(
            onTap: () {
              setState(() => _selectedNode = isSelected ? null : node);
              if (_isQuickEditMode && !isSelected) {
                _editNodeDirectly(node);
              }
            },
            borderRadius: _getBorderRadius(node.effectiveShape),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildShapeIcon(node),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isRoot ? FontWeight.bold : FontWeight.w500,
                        fontFamily: 'Caveat', // Use handwriting font
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isSelected)
                    IconButton(
                      icon: Icon(Icons.add_circle, size: 20, color: node.color),
                      onPressed: () => _addNode(node.id),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  BorderRadius _getBorderRadius(String shape) {
    switch (shape) {
      case 'circle':
        return BorderRadius.circular(_nodeWidth / 2);
      case 'cloud':
        return BorderRadius.circular(20);
      case 'star':
        return BorderRadius.circular(15);
      default:
        return BorderRadius.circular(12);
    }
  }

  List<BoxShadow> _getShadows(bool isSelected) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: isSelected ? 0.15 : 0.08),
        blurRadius: isSelected ? 12 : 6,
        offset: Offset(0, isSelected ? 4 : 2),
      ),
    ];
  }

  Widget _buildShapeIcon(MindMapNode node) {
    IconData icon;
    switch (node.effectiveShape) {
      case 'circle':
        return Icon(Icons.circle, color: node.color, size: 20);
      case 'cloud':
        icon = Icons.cloud;
        break;
      case 'star':
        icon = Icons.star;
        break;
      default:
        icon = Icons.rectangle_rounded;
    }
    return Icon(icon, color: node.color, size: 14);
  }

  Widget _buildControls(ColorScheme colorScheme) {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: SafeArea(
        child:
            _simpleMode
                ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: colorScheme.outline),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _buildToolbarItems(colorScheme),
                )
                : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.3,
                          ),
                        ),
                      ),
                      child: _buildToolbarItems(colorScheme),
                    ),
                  ),
                ),
      ),
    );
  }

  Widget _buildToolbarItems(ColorScheme colorScheme) {
    return Row(
      children: [
        _buildToolbarButton(
          icon: Icons.center_focus_strong,
          onPressed: _centerOnNodes,
          colorScheme: colorScheme,
          tooltip: 'center'.tr(),
        ),
        const Spacer(),
        IconButton(
          onPressed: () => _zoom(0.25),
          icon: const Icon(Icons.add, size: 20),
          tooltip: 'zoom_in'.tr(),
          visualDensity: VisualDensity.compact,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            '${(_currentScale * 100).toInt()}%',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(
          onPressed: () => _zoom(-0.25),
          icon: const Icon(Icons.remove, size: 20),
          tooltip: 'zoom_out'.tr(),
          visualDensity: VisualDensity.compact,
        ),
        const SizedBox(width: 4),
        _buildToolbarButton(
          icon: _showMinimap ? Icons.map : Icons.map_outlined,
          onPressed: () => setState(() => _showMinimap = !_showMinimap),
          colorScheme: colorScheme,
          isActive: _showMinimap,
          tooltip: 'minimap'.tr(),
        ),
        const SizedBox(width: 4),
        _buildLayoutToggle(colorScheme),
        const SizedBox(width: 4),
        _buildQuickEditModeToggle(colorScheme),
        const SizedBox(width: 4),
        _buildToolbarButton(
          icon: _simpleMode ? Icons.style_outlined : Icons.style,
          onPressed: () => setState(() => _simpleMode = !_simpleMode),
          colorScheme: colorScheme,
          isActive: !_simpleMode,
          tooltip: 'Toggle Theme',
        ),
      ],
    );
  }

  Widget _buildLayoutToggle(ColorScheme colorScheme) {
    final isVertical = widget.mindMap.effectiveLayoutType == 'vertical';
    return _buildToolbarButton(
      icon:
          isVertical
              ? Icons.vertical_align_bottom
              : Icons.horizontal_distribute,
      onPressed: () {
        final newLayout = isVertical ? 'horizontal' : 'vertical';
        final updated = _applyAutoLayout(widget.mindMap, newLayout);
        widget.onNodeUpdated(updated.copyWith(layoutType: newLayout));
      },
      colorScheme: colorScheme,
      isActive: true,
      tooltip: 'toggle_layout'.tr(),
    );
  }

  Widget _buildQuickEditModeToggle(ColorScheme colorScheme) {
    return _buildToolbarButton(
      icon: _isQuickEditMode ? Icons.edit_off : Icons.edit,
      onPressed: () {
        setState(() => _isQuickEditMode = !_isQuickEditMode);
      },
      colorScheme: colorScheme,
      isActive: _isQuickEditMode,
      tooltip:
          _isQuickEditMode
              ? 'disable_quick_edit'.tr()
              : 'enable_quick_edit'.tr(),
    );
  }

  MindMapNode _applyAutoLayout(MindMapNode root, String type) {
    // Simple recursive layout algorithm placeholder
    // For now, let's just rotate the existing coordinates as a simple toggle effect
    return _rotateNodes(root);
  }

  MindMapNode _rotateNodes(MindMapNode node) {
    final List<MindMapNode> newChildren =
        node.children.map((c) => _rotateNodes(c)).toList();
    // Swap x and y relative to parent (very simple pivot)
    return node.copyWith(x: node.y, y: node.x, children: newChildren);
  }

  Widget _buildToolbarButton({
    required IconData icon,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    bool isActive = false,
    String? tooltip,
  }) {
    return Material(
      color:
          isActive
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            border: Border.all(
              color:
                  isActive
                      ? colorScheme.primary.withValues(alpha: 0.5)
                      : colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Tooltip(
            message: tooltip ?? '',
            child: Icon(
              icon,
              size: 22,
              color:
                  isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditor(ColorScheme colorScheme) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _selectedNode!.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedNode!.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${_selectedNode!.children.length} ${'children'.tr()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildActionChip(
                      icon: Icons.add,
                      label: 'add_child',
                      onTap: () => _addNode(_selectedNode!.id),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      icon: Icons.edit,
                      label: 'edit',
                      onTap: () => _editNode(_selectedNode!),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      icon: Icons.category,
                      label: 'shape',
                      onTap: () => _cycleShape(_selectedNode!),
                      colorScheme: colorScheme,
                    ),
                    const SizedBox(width: 8),
                    _buildActionChip(
                      icon: Icons.gradient,
                      label: 'gradient',
                      onTap: () => _toggleGradient(_selectedNode!),
                      colorScheme: colorScheme,
                    ),
                    if (_selectedNode!.id != widget.mindMap.id) ...[
                      const SizedBox(width: 8),
                      _buildActionChip(
                        icon: Icons.delete,
                        label: 'delete',
                        onTap: () => _deleteNode(_selectedNode!, colorScheme),
                        isDestructive: true,
                        colorScheme: colorScheme,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _cycleShape(MindMapNode node) {
    final shapes = ['rectangle', 'circle', 'cloud', 'star'];
    final currentIndex = shapes.indexOf(node.effectiveShape);
    final nextIndex = (currentIndex + 1) % shapes.length;
    widget.onNodeUpdated(
      widget.mindMap.updateNode(
        node.id,
        (n) => n.copyWith(shape: shapes[nextIndex]),
      ),
    );
    setState(() {
      _selectedNode = _selectedNode?.copyWith(shape: shapes[nextIndex]);
    });
  }

  void _editNodeDirectly(MindMapNode node) {
    showDialog(
      context: context,
      builder:
          (ctx) => _MindMapQuickEditDialog(
            node: node,
            onSave: (newLabel) {
              final updated = widget.mindMap.updateNode(
                node.id,
                (n) => n.copyWith(label: newLabel),
              );
              widget.onNodeUpdated(updated);
            },
          ),
    );
  }

  void _toggleGradient(MindMapNode node) {
    final nextValue = !node.effectiveUseGradient;
    widget.onNodeUpdated(
      widget.mindMap.updateNode(
        node.id,
        (n) => n.copyWith(useGradient: nextValue),
      ),
    );
    setState(() {
      if (_selectedNode?.id == node.id) {
        _selectedNode = _selectedNode?.copyWith(useGradient: nextValue);
      }
    });
  }

  Widget _buildActionChip({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    bool isDestructive = false,
  }) {
    return Material(
      color:
          isDestructive
              ? colorScheme.errorContainer
              : colorScheme.primaryContainer,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color:
                    isDestructive
                        ? colorScheme.onErrorContainer
                        : colorScheme.onPrimaryContainer,
              ),
              const SizedBox(width: 8),
              Text(
                label.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color:
                      isDestructive
                          ? colorScheme.onErrorContainer
                          : colorScheme.onPrimaryContainer,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addNode(String parentId) {
    showDialog(
      context: context,
      builder:
          (ctx) => MindMapNodeEditor(
            title: 'add_node'.tr(),
            buttonText: 'add'.tr(),
            initialText: '',
            onSubmit: (label) {
              if (label.trim().isEmpty) return;
              final parent = _findNode(widget.mindMap, parentId);
              if (parent == null) return;
              final newNode = MindMapNode.create(
                label: label.trim(),
                x: parent.x + _levelSpacing,
                y: parent.y + parent.children.length * _siblingSpacing,
              );
              widget.onNodeUpdated(widget.mindMap.addChild(parentId, newNode));
            },
          ),
    );
  }

  void _editNode(MindMapNode node) {
    showDialog(
      context: context,
      builder:
          (ctx) => MindMapNodeEditor(
            title: 'edit_node'.tr(),
            buttonText: 'save'.tr(),
            initialText: node.label,
            onSubmit: (label) {
              if (label.trim().isEmpty) return;
              widget.onNodeUpdated(
                widget.mindMap.updateNode(
                  node.id,
                  (n) => n.copyWith(label: label.trim()),
                ),
              );
            },
          ),
    );
  }

  void _deleteNode(MindMapNode node, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('delete_node'.tr()),
            content: Text('delete_node_confirm'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('cancel'.tr()),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  widget.onNodeUpdated(widget.mindMap.removeChild(node.id));
                  setState(() => _selectedNode = null);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.error,
                ),
                child: Text('delete'.tr()),
              ),
            ],
          ),
    );
  }

  MindMapNode? _findNode(MindMapNode root, String id) {
    if (root.id == id) return root;
    for (final child in root.children) {
      final result = _findNode(child, id);
      if (result != null) return result;
    }
    return null;
  }
}

class ConnectionsPainter extends CustomPainter {
  final MindMapNode root;
  final ColorScheme colorScheme;

  ConnectionsPainter({required this.root, required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    _drawConnections(canvas, root);
  }

  void _drawConnections(Canvas canvas, MindMapNode parent) {
    final isVertical = root.effectiveLayoutType == 'vertical';

    for (final child in parent.children) {
      final Offset start;
      final Offset end;

      if (isVertical) {
        start = Offset(parent.x + 90, parent.y + 60);
        end = Offset(child.x + 90, child.y);
      } else {
        start = Offset(parent.x + 180, parent.y + 30);
        end = Offset(child.x, child.y + 30);
      }

      final path = Path()..moveTo(start.dx, start.dy);

      final random = math.Random(child.id.hashCode);
      final jitterX = (random.nextDouble() - 0.5) * 15;
      final jitterY = (random.nextDouble() - 0.5) * 15;

      if (isVertical) {
        path.cubicTo(
          start.dx,
          start.dy + (end.dy - start.dy) * 0.4 + jitterY,
          end.dx,
          start.dy + (end.dy - start.dy) * 0.6 + jitterY,
          end.dx,
          end.dy,
        );
      } else {
        path.cubicTo(
          start.dx + (end.dx - start.dx) * 0.4 + jitterX,
          start.dy,
          start.dx + (end.dx - start.dx) * 0.6 + jitterX,
          end.dy,
          end.dx,
          end.dy,
        );
      }

      // 1. Glow layer (wide, soft)
      canvas.drawPath(
        path,
        Paint()
          ..color = parent.color.withValues(alpha: 0.12)
          ..strokeWidth = 6.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );

      // 2. Main organic path
      canvas.drawPath(
        path,
        Paint()
          ..color = parent.color.withValues(alpha: 0.55)
          ..strokeWidth = 2.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );

      // 3. Sketched shadow line
      canvas.save();
      canvas.translate(1.5, 0.5);
      canvas.drawPath(
        path,
        Paint()
          ..color = parent.color.withValues(alpha: 0.15)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();

      // 4. Small dot at connection point
      canvas.drawCircle(
        end,
        3.5,
        Paint()
          ..color = child.color.withValues(alpha: 0.5)
          ..style = PaintingStyle.fill,
      );

      _drawConnections(canvas, child);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Quick Edit Dialog for MindMap nodes
class _MindMapQuickEditDialog extends StatefulWidget {
  final MindMapNode node;
  final Function(String) onSave;

  const _MindMapQuickEditDialog({required this.node, required this.onSave});

  @override
  State<_MindMapQuickEditDialog> createState() =>
      _MindMapQuickEditDialogState();
}

class _MindMapQuickEditDialogState extends State<_MindMapQuickEditDialog> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.node.label);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('quick_edit_node'.tr()),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'node_label'.tr(),
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        FilledButton(
          onPressed: () {
            if (_controller.text.trim().isNotEmpty) {
              widget.onSave(_controller.text.trim());
              Navigator.pop(context);
            }
          },
          child: Text('save'.tr()),
        ),
      ],
    );
  }
}
