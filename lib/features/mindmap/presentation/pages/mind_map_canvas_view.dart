import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/models/mind_map_node.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/node_editor_panel.dart';
import '../widgets/canvas_minimap.dart';
import '../widgets/canvas_controller.dart';
import '../widgets/canvas_renderer.dart';
import '../widgets/gesture_handler.dart';

/// Professional canvas-based mind map view with advanced features
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

class _MindMapCanvasViewState extends State<MindMapCanvasView> {
  // Controllers
  late final CanvasController _canvasController;
  late final GestureHandler _gestureHandler;

  // Focus
  final FocusNode _focusNode = FocusNode();

  // UI State
  bool _showGrid = true;
  bool _snapToGrid = true;
  final bool _showMinimap = true;
  bool _showOverlays = true;
  CanvasMode _mode = CanvasMode.select;
  Size _viewportSize = Size.zero;

  // Selection
  MindMapNode? _selectedNode;
  final Set<String> _multiSelectedNodes = {};

  static const double _nodeWidth = 180.0;
  static const double _nodeHeight = 60.0;
  static const double _levelSpacing = 120.0;
  static const double _siblingSpacing = 40.0;
  static const double _gridMagnetScreenThreshold = 8.0;
  static const double _gridMagnetStrength = 0.45;

  @override
  void initState() {
    super.initState();

    // Initialize canvas controller
    _canvasController = CanvasController(
      initialMindMap: widget.mindMap,
      onUpdate: _handleCanvasUpdate,
    );

    // Initialize gesture handler
    _gestureHandler = GestureHandler(
      controller: _canvasController,
      onNodeSelected: _handleNodeSelection,
      onNodeMoved: _handleNodeMoved,
      onNodeDragEnd: _handleNodeDragEnd,
      onCanvasPanned: _handleCanvasPan,
      onCanvasZoomed: _handleCanvasZoom,
      getViewportSize: () => _viewportSize,
    );
    _gestureHandler.panOnly = _mode == CanvasMode.pan;

    // Auto-center on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _centerOnContent();
    });
  }

  @override
  void dispose() {
    _canvasController.dispose();
    _gestureHandler.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleCanvasUpdate(MindMapNode updatedMindMap) {
    widget.onNodeUpdated(updatedMindMap);

    final selectedId = _selectedNode?.id;
    final updatedSelected =
        selectedId != null ? _canvasController.findNode(selectedId) : null;
    final validIds = _canvasController.getAllNodeIds().toSet();
    final updatedMulti = _multiSelectedNodes.where(validIds.contains).toSet();

    if (updatedSelected != _selectedNode ||
        !setEquals(updatedMulti, _multiSelectedNodes)) {
      setState(() {
        _selectedNode = updatedSelected;
        _multiSelectedNodes
          ..clear()
          ..addAll(updatedMulti);
      });
    }
  }

  void _handleNodeSelection(String? nodeId, {bool multiSelect = false}) {
    final isModifierPressed =
        HardwareKeyboard.instance.isShiftPressed ||
        HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
    final isMultiSelect = multiSelect || isModifierPressed;

    setState(() {
      if (nodeId == null) {
        if (!isMultiSelect) {
          _selectedNode = null;
          _multiSelectedNodes.clear();
        }
      } else {
        final node = _canvasController.findNode(nodeId);
        if (isMultiSelect) {
          if (_multiSelectedNodes.contains(nodeId)) {
            _multiSelectedNodes.remove(nodeId);
            if (_selectedNode?.id == nodeId) {
              _selectedNode =
                  _multiSelectedNodes.isNotEmpty
                      ? _canvasController.findNode(_multiSelectedNodes.last)
                      : null;
            }
          } else {
            _multiSelectedNodes.add(nodeId);
          }
          _selectedNode = node;
        } else {
          _selectedNode = node;
          _multiSelectedNodes.clear();
          if (nodeId.isNotEmpty) {
            _multiSelectedNodes.add(nodeId);
          }
        }
      }
    });
  }

  void _handleNodeMoved(String nodeId, Offset delta) {
    final thresholdWorld = _gridMagnetScreenThreshold / _canvasController.zoom;

    if (_multiSelectedNodes.isNotEmpty &&
        _multiSelectedNodes.contains(nodeId)) {
      if (_snapToGrid) {
        _canvasController.moveNodesMagnetic(
          _multiSelectedNodes,
          anchorNodeId: nodeId,
          delta: delta,
          threshold: thresholdWorld,
          strength: _gridMagnetStrength,
        );
      } else {
        _canvasController.moveNodes(
          _multiSelectedNodes,
          delta,
          snapToGrid: false,
        );
      }
    } else {
      if (_snapToGrid) {
        _canvasController.moveNodeMagnetic(
          nodeId,
          delta,
          threshold: thresholdWorld,
          strength: _gridMagnetStrength,
        );
      } else {
        _canvasController.moveNode(nodeId, delta, snapToGrid: false);
      }
    }
  }

  void _handleNodeDragEnd(String nodeId) {
    if (!_snapToGrid) return;
    final thresholdWorld = _gridMagnetScreenThreshold / _canvasController.zoom;
    if (_multiSelectedNodes.isNotEmpty &&
        _multiSelectedNodes.contains(nodeId)) {
      _canvasController.snapNodesToGrid(
        _multiSelectedNodes,
        threshold: thresholdWorld,
        anchorNodeId: nodeId,
      );
    } else {
      _canvasController.snapNodeToGrid(nodeId, threshold: thresholdWorld);
    }
  }

  void _handleCanvasPan(Offset delta) {
    _canvasController.pan(delta);
  }

  void _handleCanvasZoom(double delta, Offset focalPoint) {
    _canvasController.applyZoom(delta, focalPoint: focalPoint);
  }

  void _deleteSelectedNode() {
    if (_selectedNode == null) return;

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
                  _canvasController.deleteNode(_selectedNode!.id);
                  setState(() {
                    _selectedNode = null;
                    _multiSelectedNodes.clear();
                  });
                },
                child: Text('delete'.tr()),
              ),
            ],
          ),
    );
  }

  void _copySelectedNode() {
    if (_selectedNode == null) return;
    _canvasController.copyNode(_selectedNode!.id);
  }

  void _pasteNode() {
    _canvasController.pasteNode();
  }

  void _selectAll() {
    final allNodes = _canvasController.getAllNodeIds();
    setState(() {
      _multiSelectedNodes.clear();
      _multiSelectedNodes.addAll(allNodes);
    });
  }

  void _moveSelection(Offset delta) {
    if (_multiSelectedNodes.isNotEmpty) {
      _canvasController.moveNodes(
        _multiSelectedNodes,
        delta,
        snapToGrid: _snapToGrid,
      );
      return;
    }
    if (_selectedNode == null) return;
    _canvasController.moveNode(
      _selectedNode!.id,
      delta,
      snapToGrid: _snapToGrid,
    );
  }

  void _toggleGrid() {
    setState(() => _showGrid = !_showGrid);
  }

  void _clearSelection() {
    setState(() {
      _selectedNode = null;
      _multiSelectedNodes.clear();
    });
  }

  void _toggleOverlays() {
    setState(() => _showOverlays = !_showOverlays);
  }

  void _runAutoLayout() {
    _applyAutoLayout(addToHistory: true);
  }

  void _applyAutoLayout({required bool addToHistory}) {
    final root = _canvasController.currentMindMap;
    final laidOut = _autoLayout(root).copyWith(layoutType: 'vertical');
    _canvasController.setMindMap(laidOut, addToHistory: addToHistory);
  }

  MindMapNode _autoLayout(MindMapNode root) {
    final subtreeWidth = <String, double>{};

    double computeWidth(MindMapNode node) {
      if (node.children.isEmpty) {
        subtreeWidth[node.id] = _nodeWidth;
        return _nodeWidth;
      }

      var total = 0.0;
      for (final child in node.children) {
        total += computeWidth(child);
      }
      total += _siblingSpacing * (node.children.length - 1);
      final width = math.max(_nodeWidth, total);
      subtreeWidth[node.id] = width;
      return width;
    }

    computeWidth(root);

    final rootCenterX = root.x + _nodeWidth / 2;
    final rootTopY = root.y;

    MindMapNode layoutNode(MindMapNode node, double centerX, double topY) {
      final nodeX = centerX - _nodeWidth / 2;
      final nodeY = topY;

      if (node.children.isEmpty) {
        return node.copyWith(x: nodeX, y: nodeY, children: const []);
      }

      final childrenBlock =
          node.children.fold<double>(
            0,
            (sum, child) => sum + (subtreeWidth[child.id] ?? _nodeWidth),
          ) +
          _siblingSpacing * (node.children.length - 1);

      var cursorX = centerX - childrenBlock / 2;
      final childTopY = topY + _nodeHeight + _levelSpacing;

      final newChildren = <MindMapNode>[];
      for (final child in node.children) {
        final childWidth = subtreeWidth[child.id] ?? _nodeWidth;
        final childCenterX = cursorX + childWidth / 2;
        newChildren.add(layoutNode(child, childCenterX, childTopY));
        cursorX += childWidth + _siblingSpacing;
      }

      return node.copyWith(x: nodeX, y: nodeY, children: newChildren);
    }

    return layoutNode(root, rootCenterX, rootTopY);
  }

  void _centerOnContent() {
    _canvasController.centerOnContent(viewportSize: _viewportSize);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final isControlPressed =
              HardwareKeyboard.instance.isControlPressed ||
              HardwareKeyboard.instance.isMetaPressed;
          final isShiftPressed = HardwareKeyboard.instance.isShiftPressed;

          // Delete/Backspace
          if (event.logicalKey == LogicalKeyboardKey.delete ||
              event.logicalKey == LogicalKeyboardKey.backspace) {
            _deleteSelectedNode();
            return KeyEventResult.handled;
          }

          // Ctrl+C (Copy)
          if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyC) {
            _copySelectedNode();
            return KeyEventResult.handled;
          }

          // Ctrl+V (Paste)
          if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyV) {
            _pasteNode();
            return KeyEventResult.handled;
          }

          // Ctrl+Z (Undo)
          if (isControlPressed &&
              !isShiftPressed &&
              event.logicalKey == LogicalKeyboardKey.keyZ) {
            _canvasController.undo();
            return KeyEventResult.handled;
          }

          // Ctrl+Shift+Z (Redo)
          if (isControlPressed &&
              isShiftPressed &&
              event.logicalKey == LogicalKeyboardKey.keyZ) {
            _canvasController.redo();
            return KeyEventResult.handled;
          }

          // Ctrl+A (Select All)
          if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyA) {
            _selectAll();
            return KeyEventResult.handled;
          }

          // Ctrl++ (Zoom In)
          if (isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.equal) {
            _canvasController.zoomIn();
            return KeyEventResult.handled;
          }

          // Ctrl+- (Zoom Out)
          if (isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.minus) {
            _canvasController.zoomOut();
            return KeyEventResult.handled;
          }

          // Ctrl+0 (Reset Zoom)
          if (isControlPressed &&
              event.logicalKey == LogicalKeyboardKey.digit0) {
            _canvasController.resetZoom();
            return KeyEventResult.handled;
          }

          // Ctrl+G (Toggle Grid)
          if (isControlPressed && event.logicalKey == LogicalKeyboardKey.keyG) {
            _toggleGrid();
            return KeyEventResult.handled;
          }

          // Arrow keys (Move selection)
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _moveSelection(const Offset(0, -20));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _moveSelection(const Offset(0, 20));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            _moveSelection(const Offset(-20, 0));
            return KeyEventResult.handled;
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            _moveSelection(const Offset(20, 0));
            return KeyEventResult.handled;
          }

          // Escape (Clear selection)
          if (event.logicalKey == LogicalKeyboardKey.escape) {
            _clearSelection();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Scaffold(
        body: Stack(
          children: [
            // Main Canvas
            _buildCanvas(colorScheme),

            Positioned(
              top: 72,
              right: 12,
              child: SafeArea(child: _buildOverlayToggle(colorScheme)),
            ),

            // Top Toolbar
            if (_showOverlays)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: CanvasToolbar(
                    controller: _canvasController,
                    mode: _mode,
                    onModeChanged: (mode) {
                      setState(() => _mode = mode);
                      _gestureHandler.panOnly = mode == CanvasMode.pan;
                    },
                    showGrid: _showGrid,
                    onToggleGrid: () => setState(() => _showGrid = !_showGrid),
                    snapToGrid: _snapToGrid,
                    onToggleSnap:
                        () => setState(() => _snapToGrid = !_snapToGrid),
                    onZoomIn: () => _canvasController.zoomIn(),
                    onZoomOut: () => _canvasController.zoomOut(),
                    onResetZoom: () => _canvasController.resetZoom(),
                    onCenter: _centerOnContent,
                    onAutoLayout: _runAutoLayout,
                    onUndo:
                        _canvasController.canUndo
                            ? _canvasController.undo
                            : null,
                    onRedo:
                        _canvasController.canRedo
                            ? _canvasController.redo
                            : null,
                  ),
                ),
              ),

            // Node Editor Panel
            if (_showOverlays && _selectedNode != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: NodeEditorPanel(
                    node: _selectedNode!,
                    onUpdate: (updatedNode) {
                      _canvasController.updateNode(updatedNode);
                    },
                    onAddChild: () => _showAddNodeDialog(_selectedNode!.id),
                    onDelete: _deleteSelectedNode,
                    onClose: _clearSelection,
                  ),
                ),
              ),

            // Minimap
            if (_showOverlays && _showMinimap)
              Positioned(
                bottom: _selectedNode != null ? 220 : 20,
                right: 20,
                child: CanvasMinimap(
                  controller: _canvasController,
                  viewportSize: _viewportSize,
                  width: 200,
                  height: 150,
                ),
              ),

            if (_showOverlays)
              Positioned(
                bottom: _selectedNode != null ? 220 : 20,
                left: 20,
                child: _buildZoomControls(colorScheme),
              ),

            // Canvas Stats (Debug)
            if (const bool.fromEnvironment('DEBUG'))
              Positioned(top: 100, left: 20, child: _buildDebugStats()),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas(ColorScheme colorScheme) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final newSize = Size(constraints.maxWidth, constraints.maxHeight);
        if (_viewportSize != newSize) {
          _viewportSize = newSize;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {});
          });
        }
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            _focusNode.requestFocus();
            _gestureHandler.handleTapDown(details);
          },
          onTapUp: (details) => _gestureHandler.handleTapUp(details),
          onLongPressStart:
              (details) => _gestureHandler.handleLongPressStart(details),
          onScaleStart: (details) => _gestureHandler.handleScaleStart(details),
          onScaleUpdate:
              (details) => _gestureHandler.handleScaleUpdate(details),
          onScaleEnd: (details) => _gestureHandler.handleScaleEnd(details),
          child: Listener(
            onPointerSignal: (event) {
              if (event is PointerScrollEvent) {
                _gestureHandler.handleScroll(event);
              }
            },
            child: AnimatedBuilder(
              animation: _canvasController,
              builder: (context, _) {
                return CustomPaint(
                  painter: CanvasRenderer(
                    controller: _canvasController,
                    selectedNodeId: _selectedNode?.id,
                    multiSelectedNodeIds: _multiSelectedNodes,
                    showGrid: _showGrid,
                    gridSize: _canvasController.gridSize,
                    colorScheme: colorScheme,
                  ),
                  size: Size.infinite,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildZoomControls(ColorScheme colorScheme) {
    return Material(
      color: colorScheme.surface.withValues(alpha: 0.95),
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: AnimatedBuilder(
        animation: _canvasController,
        builder: (context, _) {
          final zoomText = '${(_canvasController.zoom * 100).toInt()}%';
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildZoomIconButton(
                icon: Icons.add,
                tooltip: 'zoom_in'.tr(),
                onPressed: _canvasController.zoomIn,
                colorScheme: colorScheme,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Text(
                  zoomText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              _buildZoomIconButton(
                icon: Icons.remove,
                tooltip: 'zoom_out'.tr(),
                onPressed: _canvasController.zoomOut,
                colorScheme: colorScheme,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildZoomIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    required ColorScheme colorScheme,
    required BorderRadius borderRadius,
  }) {
    final button = InkWell(
      onTap: onPressed,
      borderRadius: borderRadius,
      child: SizedBox(
        width: 44,
        height: 44,
        child: Icon(icon, color: colorScheme.onSurface),
      ),
    );

    return Tooltip(message: tooltip, child: button);
  }

  Widget _buildOverlayToggle(ColorScheme colorScheme) {
    final isVisible = _showOverlays;
    final icon = isVisible ? Icons.visibility_off : Icons.visibility;
    final tooltip = isVisible ? 'hide_tools'.tr() : 'show_tools'.tr();

    return Tooltip(
      message: tooltip,
      child: Material(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          onTap: _toggleOverlays,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Icon(icon, size: 20, color: colorScheme.onSurface),
          ),
        ),
      ),
    );
  }

  Widget _buildDebugStats() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: AnimatedBuilder(
        animation: _canvasController,
        builder: (context, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Zoom: ${(_canvasController.zoom * 100).toInt()}%',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Offset: ${_canvasController.offset.dx.toInt()}, ${_canvasController.offset.dy.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'Nodes: ${_canvasController.getAllNodeIds().length}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
              Text(
                'FPS: ${_canvasController.fps.toInt()}',
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddNodeDialog(String parentId) {
    showDialog(
      context: context,
      builder:
          (ctx) => _AddNodeDialog(
            onSubmit: (label, color) {
              final newNode = MindMapNode.create(
                label: label,
                colorValue: color.toARGB32(),
              );
              _canvasController.addNode(parentId, newNode);
            },
          ),
    );
  }
}

/// Dialog for adding new nodes
class _AddNodeDialog extends StatefulWidget {
  final Function(String label, Color color) onSubmit;

  const _AddNodeDialog({required this.onSubmit});

  @override
  State<_AddNodeDialog> createState() => _AddNodeDialogState();
}

class _AddNodeDialogState extends State<_AddNodeDialog> {
  final _controller = TextEditingController();
  Color _selectedColor = const Color(0xFF2196F3);

  static const _colors = [
    Color(0xFF2196F3), // Blue
    Color(0xFF4CAF50), // Green
    Color(0xFFF44336), // Red
    Color(0xFFFF9800), // Orange
    Color(0xFF9C27B0), // Purple
    Color(0xFFE91E63), // Pink
    Color(0xFF00BCD4), // Cyan
    Color(0xFFFFEB3B), // Yellow
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('add_node'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'node_label'.tr(),
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                _colors.map((color) {
                  final isSelected = color == _selectedColor;
                  return InkWell(
                    onTap: () => setState(() => _selectedColor = color),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow:
                            isSelected
                                ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                                : null,
                      ),
                      child:
                          isSelected
                              ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                              : null,
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        FilledButton(onPressed: _submit, child: Text('add'.tr())),
      ],
    );
  }

  void _submit() {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    widget.onSubmit(label, _selectedColor);
    Navigator.pop(context);
  }
}
