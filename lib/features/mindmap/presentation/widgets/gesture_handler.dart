import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'canvas_controller.dart';

/// Advanced gesture handler with multi-touch support and intelligent recognition
class GestureHandler {
  GestureHandler({
    required this.controller,
    required this.onNodeSelected,
    required this.onNodeMoved,
    this.onNodeDragEnd,
    required this.onCanvasPanned,
    required this.onCanvasZoomed,
    this.getViewportSize,
  });

  final CanvasController controller;
  final Function(String? nodeId, {bool multiSelect}) onNodeSelected;
  final Function(String nodeId, Offset delta) onNodeMoved;
  final void Function(String nodeId)? onNodeDragEnd;
  final Function(Offset delta) onCanvasPanned;
  final Function(double delta, Offset focalPoint) onCanvasZoomed;
  final Size Function()? getViewportSize;

  bool panOnly = false;

  // State
  String? _draggedNodeId;
  Offset _lastDragPosition = Offset.zero;
  double _lastScale = 1.0;
  Offset _lastFocalPoint = Offset.zero;
  bool _isScaling = false;
  bool _didDrag = false;
  DateTime? _lastTapTime;
  Offset? _lastTapUpPosition;

  // Configuration
  static const double _doubleTapThreshold = 300.0; // ms
  static const double _tapDistanceThreshold = 20.0; // pixels
  static const double _minimumDragDistance = 5.0; // pixels
  static const double _scrollSensitivity = 0.001;

  void handleTapDown(TapDownDetails details) {
    // Reserved for future gesture expansions.
  }

  void handleTapUp(TapUpDetails details) {
    if (panOnly) return;

    final now = DateTime.now();
    final position = details.localPosition;

    // Check for double tap
    if (_lastTapTime != null && _lastTapUpPosition != null) {
      final timeDiff = now.difference(_lastTapTime!).inMilliseconds;
      final distanceDiff = (position - _lastTapUpPosition!).distance;

      if (timeDiff < _doubleTapThreshold &&
          distanceDiff < _tapDistanceThreshold) {
        _handleDoubleTap(position);
        _lastTapTime = null;
        _lastTapUpPosition = null;
        return;
      }
    }

    _lastTapTime = now;
    _lastTapUpPosition = position;

    // Single tap - select node
    final nodeId = controller.getNodeAtPosition(position);

    // Check for multi-select (Shift key would be handled by keyboard events)
    onNodeSelected(nodeId, multiSelect: false);
  }

  void handleDoubleTap(TapDownDetails details) {
    _handleDoubleTap(details.localPosition);
  }

  void _handleDoubleTap(Offset position) {
    final nodeId = controller.getNodeAtPosition(position);
    if (nodeId != null) {
      // Double tap on node - could trigger edit
      // For now, just center on it
      final node = controller.findNode(nodeId);
      if (node != null) {
        _centerOnNode(node.x, node.y);
      }
    } else {
      // Double tap on canvas - reset zoom
      controller.resetZoom();
    }
  }

  void _centerOnNode(double x, double y) {
    final viewportSize = getViewportSize?.call();
    if (viewportSize == null || viewportSize.isEmpty) return;

    controller.centerOnPoint(
      Offset(x + 90, y + 30),
      viewportSize: viewportSize,
    );
  }

  void handleLongPressStart(LongPressStartDetails details) {
    if (panOnly) return;

    final nodeId = controller.getNodeAtPosition(details.localPosition);
    if (nodeId != null) {
      // Long press could trigger context menu
      onNodeSelected(nodeId, multiSelect: false);
    }
  }

  void handleScaleStart(ScaleStartDetails details) {
    _lastFocalPoint = details.localFocalPoint;
    _lastScale = 1.0;
    _isScaling = false;
    _didDrag = false;

    // Check if we're starting a drag on a node
    if (!panOnly) {
      final nodeId = controller.getNodeAtPosition(details.localFocalPoint);
      if (nodeId != null) {
        _draggedNodeId = nodeId;
        _lastDragPosition = details.localFocalPoint;
      } else {
        _draggedNodeId = null;
      }
    } else {
      _draggedNodeId = null;
    }
  }

  void handleScaleUpdate(ScaleUpdateDetails details) {
    final localFocalPoint = details.localFocalPoint;

    // Determine gesture type based on scale and movement
    final scaleDelta = (details.scale - _lastScale).abs();
    final moveDelta = (localFocalPoint - _lastFocalPoint).distance;

    if (details.pointerCount == 2 || scaleDelta > 0.01) {
      // Multi-finger or significant scale change - zoom
      _isScaling = true;
      _handleZoom(details, localFocalPoint);
    } else if (panOnly) {
      _handlePan(details, localFocalPoint);
    } else if (_draggedNodeId != null && !_isScaling) {
      // Single finger drag on node
      _handleNodeDrag(details, localFocalPoint);
    } else if (!_isScaling && moveDelta > _minimumDragDistance) {
      // Single finger pan
      _handlePan(details, localFocalPoint);
    }

    _lastFocalPoint = localFocalPoint;
    _lastScale = details.scale;
  }

  void handleScaleEnd(ScaleEndDetails details) {
    final draggedNodeId = _draggedNodeId;
    if (_didDrag && draggedNodeId != null) {
      onNodeDragEnd?.call(draggedNodeId);
    }
    _draggedNodeId = null;
    _isScaling = false;
    _didDrag = false;
  }

  void _handleNodeDrag(ScaleUpdateDetails details, Offset localFocalPoint) {
    if (_draggedNodeId == null) return;

    final delta = localFocalPoint - _lastDragPosition;

    // Only drag if moved enough (prevents accidental drags)
    if (delta.distance > _minimumDragDistance) {
      onNodeMoved(_draggedNodeId!, delta);
      _lastDragPosition = localFocalPoint;
      _didDrag = true;
    }
  }

  void _handlePan(ScaleUpdateDetails details, Offset localFocalPoint) {
    final delta = localFocalPoint - _lastFocalPoint;
    onCanvasPanned(delta);
  }

  void _handleZoom(ScaleUpdateDetails details, Offset localFocalPoint) {
    final scaleDelta = details.scale - _lastScale;
    onCanvasZoomed(scaleDelta, localFocalPoint);
  }

  void handleScroll(PointerScrollEvent event) {
    // Mouse wheel zoom
    final delta = -event.scrollDelta.dy * _scrollSensitivity;
    onCanvasZoomed(delta, event.localPosition);
  }

  void dispose() {
    // Cleanup if needed
  }
}

/// Enum for gesture types
enum GestureType { none, tap, doubleTap, longPress, drag, pan, zoom, rotate }

/// Gesture state for advanced tracking
class GestureState {
  GestureState({
    this.type = GestureType.none,
    this.position = Offset.zero,
    this.delta = Offset.zero,
    this.scale = 1.0,
    this.rotation = 0.0,
    this.velocity = Velocity.zero,
  });

  final GestureType type;
  final Offset position;
  final Offset delta;
  final double scale;
  final double rotation;
  final Velocity velocity;

  GestureState copyWith({
    GestureType? type,
    Offset? position,
    Offset? delta,
    double? scale,
    double? rotation,
    Velocity? velocity,
  }) {
    return GestureState(
      type: type ?? this.type,
      position: position ?? this.position,
      delta: delta ?? this.delta,
      scale: scale ?? this.scale,
      rotation: rotation ?? this.rotation,
      velocity: velocity ?? this.velocity,
    );
  }
}
