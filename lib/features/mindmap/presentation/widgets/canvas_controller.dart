import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../domain/models/mind_map_node.dart';

/// Advanced canvas controller with undo/redo, animations, and optimization
class CanvasController extends ChangeNotifier {
  CanvasController({
    required MindMapNode initialMindMap,
    required this.onUpdate,
  }) : _currentMindMap = initialMindMap {
    _initialize();
  }

  // Dependencies
  final Function(MindMapNode) onUpdate;

  // State
  MindMapNode _currentMindMap;
  final List<MindMapNode> _history = [];
  int _historyIndex = -1;
  static const int _maxHistorySize = 50;

  // Transform state
  Offset _offset = Offset.zero;
  double _zoom = 1.0;
  static const double _minZoom = 0.05;
  static const double _maxZoom = 5.0;

  // Grid
  double _gridSize = 20.0;

  // Performance
  DateTime _lastFrameTime = DateTime.now();
  double _fps = 60.0;
  final _fpsHistory = <double>[];
  static const int _fpsHistorySize = 10;
  Timer? _fpsTimer;

  // Clipboard
  MindMapNode? _clipboard;

  // Getters
  MindMapNode get currentMindMap => _currentMindMap;
  Offset get offset => _offset;
  double get zoom => _zoom;
  double get gridSize => _gridSize;
  double get fps => _fps;
  bool get canUndo => _historyIndex > 0;
  bool get canRedo => _historyIndex < _history.length - 1;

  void _initialize() {
    _pushHistory(_currentMindMap);
    _startFPSMonitor();
  }

  void _startFPSMonitor() {
    _fpsTimer?.cancel();
    _fpsTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      final now = DateTime.now();
      final delta = now.difference(_lastFrameTime).inMilliseconds;
      _lastFrameTime = now;

      if (delta > 0) {
        final currentFps = 1000 / delta;
        _fpsHistory.add(currentFps);
        if (_fpsHistory.length > _fpsHistorySize) {
          _fpsHistory.removeAt(0);
        }
        _fps = _fpsHistory.reduce((a, b) => a + b) / _fpsHistory.length;
      }
    });
  }

  /// Update mind map and trigger callbacks
  void _updateMindMap(MindMapNode newMindMap, {bool addToHistory = true}) {
    _currentMindMap = newMindMap;
    if (addToHistory) {
      _pushHistory(newMindMap);
    }
    onUpdate(newMindMap);
    notifyListeners();
  }

  void setMindMap(MindMapNode newMindMap, {bool addToHistory = true}) {
    _updateMindMap(newMindMap, addToHistory: addToHistory);
  }

  /// History management
  void _pushHistory(MindMapNode mindMap) {
    // Remove any redo history
    if (_historyIndex < _history.length - 1) {
      _history.removeRange(_historyIndex + 1, _history.length);
    }

    _history.add(mindMap);
    _historyIndex = _history.length - 1;

    // Limit history size
    if (_history.length > _maxHistorySize) {
      _history.removeAt(0);
      _historyIndex--;
    }
  }

  void undo() {
    if (!canUndo) return;
    _historyIndex--;
    _currentMindMap = _history[_historyIndex];
    onUpdate(_currentMindMap);
    notifyListeners();
  }

  void redo() {
    if (!canRedo) return;
    _historyIndex++;
    _currentMindMap = _history[_historyIndex];
    onUpdate(_currentMindMap);
    notifyListeners();
  }

  /// Transform operations
  void pan(Offset delta) {
    _offset += delta;
    notifyListeners();
  }

  void applyZoom(double delta, {Offset? focalPoint}) {
    final oldZoom = _zoom;
    _zoom = (_zoom + delta).clamp(_minZoom, _maxZoom);

    // Zoom towards focal point
    if (focalPoint != null && oldZoom != _zoom) {
      final zoomFactor = _zoom / oldZoom;
      final focalOffset = focalPoint - _offset;
      _offset = focalPoint - (focalOffset * zoomFactor);
    }

    notifyListeners();
  }

  void zoomIn() => applyZoom(0.1);
  void zoomOut() => applyZoom(-0.1);
  void resetZoom() {
    _zoom = 1.0;
    notifyListeners();
  }

  void centerOnContent({Size? viewportSize}) {
    final nodes = getAllNodes();
    if (nodes.isEmpty) return;

    // Calculate bounding box
    double minX = double.infinity;
    double maxX = double.negativeInfinity;
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (final node in nodes) {
      minX = math.min(minX, node.x);
      maxX = math.max(maxX, node.x + 180); // Node width
      minY = math.min(minY, node.y);
      maxY = math.max(maxY, node.y + 60); // Node height
    }

    final centerX = (minX + maxX) / 2;
    final centerY = (minY + maxY) / 2;

    final size = _resolveViewportSize(viewportSize);

    _offset = Offset(
      size.width / 2 - centerX * _zoom,
      size.height / 2 - centerY * _zoom,
    );

    notifyListeners();
  }

  void centerOnPoint(Offset worldPoint, {Size? viewportSize}) {
    final size = _resolveViewportSize(viewportSize);
    _offset = Offset(
      size.width / 2 - worldPoint.dx * _zoom,
      size.height / 2 - worldPoint.dy * _zoom,
    );
    notifyListeners();
  }

  /// Node operations
  MindMapNode? findNode(String id) {
    MindMapNode? find(MindMapNode node) {
      if (node.id == id) return node;
      for (final child in node.children) {
        final found = find(child);
        if (found != null) return found;
      }
      return null;
    }

    return find(_currentMindMap);
  }

  List<MindMapNode> getAllNodes() {
    final nodes = <MindMapNode>[];
    void collect(MindMapNode node) {
      nodes.add(node);
      for (final child in node.children) {
        collect(child);
      }
    }

    collect(_currentMindMap);
    return nodes;
  }

  List<String> getAllNodeIds() {
    return getAllNodes().map((n) => n.id).toList();
  }

  void moveNode(String nodeId, Offset delta, {bool snapToGrid = false}) {
    final node = findNode(nodeId);
    if (node == null) return;

    var newX = node.x + delta.dx / _zoom;
    var newY = node.y + delta.dy / _zoom;

    if (snapToGrid) {
      newX = (newX / _gridSize).round() * _gridSize;
      newY = (newY / _gridSize).round() * _gridSize;
    }

    final updatedMindMap = _currentMindMap.updateNode(
      nodeId,
      (n) => n.copyWith(x: newX, y: newY),
    );

    _updateMindMap(updatedMindMap);
  }

  void moveNodeMagnetic(
    String nodeId,
    Offset delta, {
    required double threshold,
    double strength = 0.45,
  }) {
    final node = findNode(nodeId);
    if (node == null) return;

    final deltaWorld = Offset(delta.dx / _zoom, delta.dy / _zoom);
    var newX = node.x + deltaWorld.dx;
    var newY = node.y + deltaWorld.dy;

    final snappedX = (newX / _gridSize).round() * _gridSize;
    final snappedY = (newY / _gridSize).round() * _gridSize;

    final dx = snappedX - newX;
    final dy = snappedY - newY;

    if (dx.abs() <= threshold) {
      newX += dx * strength;
    }
    if (dy.abs() <= threshold) {
      newY += dy * strength;
    }

    final updatedMindMap = _currentMindMap.updateNode(
      nodeId,
      (n) => n.copyWith(x: newX, y: newY),
    );

    _updateMindMap(updatedMindMap);
  }

  void moveNodes(Set<String> nodeIds, Offset delta, {bool snapToGrid = false}) {
    if (nodeIds.isEmpty) return;

    MindMapNode updateNode(MindMapNode node) {
      var updatedNode = node;
      if (nodeIds.contains(node.id)) {
        var newX = node.x + delta.dx / _zoom;
        var newY = node.y + delta.dy / _zoom;

        if (snapToGrid) {
          newX = (newX / _gridSize).round() * _gridSize;
          newY = (newY / _gridSize).round() * _gridSize;
        }

        updatedNode = node.copyWith(x: newX, y: newY);
      }

      final newChildren = updatedNode.children.map(updateNode).toList();
      return updatedNode.copyWith(children: newChildren);
    }

    final updatedMindMap = updateNode(_currentMindMap);
    _updateMindMap(updatedMindMap);
  }

  void moveNodesMagnetic(
    Set<String> nodeIds, {
    required String anchorNodeId,
    required Offset delta,
    required double threshold,
    double strength = 0.45,
  }) {
    if (nodeIds.isEmpty) return;

    final anchor = findNode(anchorNodeId);
    if (anchor == null) return;

    final deltaWorld = Offset(delta.dx / _zoom, delta.dy / _zoom);
    var newX = anchor.x + deltaWorld.dx;
    var newY = anchor.y + deltaWorld.dy;

    final snappedX = (newX / _gridSize).round() * _gridSize;
    final snappedY = (newY / _gridSize).round() * _gridSize;

    final dx = snappedX - newX;
    final dy = snappedY - newY;

    if (dx.abs() <= threshold) {
      newX += dx * strength;
    }
    if (dy.abs() <= threshold) {
      newY += dy * strength;
    }

    final adjustedDelta = Offset(newX - anchor.x, newY - anchor.y);

    MindMapNode updateNode(MindMapNode node) {
      var updatedNode = node;
      if (nodeIds.contains(node.id)) {
        updatedNode = node.copyWith(
          x: node.x + adjustedDelta.dx,
          y: node.y + adjustedDelta.dy,
        );
      }

      final newChildren = updatedNode.children.map(updateNode).toList();
      return updatedNode.copyWith(children: newChildren);
    }

    final updatedMindMap = updateNode(_currentMindMap);
    _updateMindMap(updatedMindMap);
  }

  void snapNodeToGrid(String nodeId, {double? threshold}) {
    final node = findNode(nodeId);
    if (node == null) return;

    final snappedX = (node.x / _gridSize).round() * _gridSize;
    final snappedY = (node.y / _gridSize).round() * _gridSize;

    var newX = node.x;
    var newY = node.y;

    if (threshold == null || (snappedX - node.x).abs() <= threshold) {
      newX = snappedX;
    }
    if (threshold == null || (snappedY - node.y).abs() <= threshold) {
      newY = snappedY;
    }

    if (newX == node.x && newY == node.y) return;

    final updatedMindMap = _currentMindMap.updateNode(
      nodeId,
      (n) => n.copyWith(x: newX, y: newY),
    );

    _updateMindMap(updatedMindMap);
  }

  void snapNodesToGrid(
    Set<String> nodeIds, {
    double? threshold,
    String? anchorNodeId,
  }) {
    if (nodeIds.isEmpty) return;

    if (anchorNodeId != null) {
      final anchor = findNode(anchorNodeId);
      if (anchor == null) return;

      final snappedX = (anchor.x / _gridSize).round() * _gridSize;
      final snappedY = (anchor.y / _gridSize).round() * _gridSize;

      var dx = snappedX - anchor.x;
      var dy = snappedY - anchor.y;

      if (threshold != null && dx.abs() > threshold) {
        dx = 0;
      }
      if (threshold != null && dy.abs() > threshold) {
        dy = 0;
      }

      if (dx == 0 && dy == 0) return;

      MindMapNode updateNode(MindMapNode node) {
        var updatedNode = node;
        if (nodeIds.contains(node.id)) {
          updatedNode = node.copyWith(x: node.x + dx, y: node.y + dy);
        }

        final newChildren = updatedNode.children.map(updateNode).toList();
        return updatedNode.copyWith(children: newChildren);
      }

      final updatedMindMap = updateNode(_currentMindMap);
      _updateMindMap(updatedMindMap);
      return;
    }

    MindMapNode updateNode(MindMapNode node) {
      var updatedNode = node;
      if (nodeIds.contains(node.id)) {
        final snappedX = (node.x / _gridSize).round() * _gridSize;
        final snappedY = (node.y / _gridSize).round() * _gridSize;
        var newX = node.x;
        var newY = node.y;

        if (threshold == null || (snappedX - node.x).abs() <= threshold) {
          newX = snappedX;
        }
        if (threshold == null || (snappedY - node.y).abs() <= threshold) {
          newY = snappedY;
        }

        updatedNode = node.copyWith(x: newX, y: newY);
      }

      final newChildren = updatedNode.children.map(updateNode).toList();
      return updatedNode.copyWith(children: newChildren);
    }

    final updatedMindMap = updateNode(_currentMindMap);
    _updateMindMap(updatedMindMap);
  }

  void addNode(String parentId, MindMapNode newNode) {
    final parent = findNode(parentId);
    if (parent == null) return;

    // Position new node relative to parent
    final positionedNode = newNode.copyWith(
      x: parent.x + 250,
      y: parent.y + parent.children.length * 80,
    );

    final updatedMindMap = _currentMindMap.addChild(parentId, positionedNode);
    _updateMindMap(updatedMindMap);
  }

  void updateNode(MindMapNode updatedNode) {
    final updatedMindMap = _currentMindMap.updateNode(
      updatedNode.id,
      (_) => updatedNode,
    );
    _updateMindMap(updatedMindMap);
  }

  void deleteNode(String nodeId) {
    // Don't allow deleting the root node
    if (nodeId == _currentMindMap.id) return;

    final updatedMindMap = _currentMindMap.removeChild(nodeId);
    _updateMindMap(updatedMindMap);
  }

  /// Clipboard operations
  void copyNode(String nodeId) {
    final node = findNode(nodeId);
    if (node != null) {
      _clipboard = node;
    }
  }

  void pasteNode() {
    if (_clipboard == null) return;

    // Create a copy with new IDs and offset position
    final newNode = _cloneNodeWithOffset(
      _clipboard!,
      const Offset(50, 50),
      labelSuffix: ' (copy)',
    );

    // Add to root or selected parent
    final parentId = _currentMindMap.id;
    addNode(parentId, newNode);
  }

  MindMapNode _cloneNodeWithOffset(
    MindMapNode node,
    Offset offset, {
    String labelSuffix = '',
  }) {
    final children =
        node.children
            .map((child) => _cloneNodeWithOffset(child, offset))
            .toList();

    return MindMapNode.create(
      label: '${node.label}$labelSuffix',
      x: node.x + offset.dx,
      y: node.y + offset.dy,
      colorValue: node.colorValue,
      layoutType: node.layoutType ?? 'horizontal',
      shape: node.shape ?? 'rectangle',
      useGradient: node.useGradient ?? false,
      children: children,
    );
  }

  /// Grid operations
  void setGridSize(double size) {
    _gridSize = size.clamp(10.0, 100.0);
    notifyListeners();
  }

  /// Screen to world coordinate conversion
  Offset screenToWorld(Offset screenPoint) {
    return (screenPoint - _offset) / _zoom;
  }

  /// World to screen coordinate conversion
  Offset worldToScreen(Offset worldPoint) {
    return worldPoint * _zoom + _offset;
  }

  /// Get node at screen position
  String? getNodeAtPosition(Offset screenPosition) {
    final worldPos = screenToWorld(screenPosition);
    final nodes = getAllNodes();

    // Check from front to back (reverse order for proper layering)
    for (final node in nodes.reversed) {
      final nodeRect = Rect.fromLTWH(node.x, node.y, 180, 60);
      if (nodeRect.contains(worldPos)) {
        return node.id;
      }
    }

    return null;
  }

  @override
  void dispose() {
    _fpsTimer?.cancel();
    super.dispose();
  }

  Size _resolveViewportSize(Size? viewportSize) {
    if (viewportSize != null &&
        viewportSize.width > 0 &&
        viewportSize.height > 0) {
      return viewportSize;
    }
    return const Size(1920, 1080);
  }
}

/// Extension to convert Color to ARGB32
extension ColorExtension on Color {
  int toARGB32() => value;
}
