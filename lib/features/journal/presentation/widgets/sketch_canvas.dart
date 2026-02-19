import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../../../../core/services/sound_service.dart';
import '../../../../core/widgets/themed_paper.dart';
import '../../../../di/injection.dart';

// ─────────────────────────────────────────────────────────────────
// Pen Types
// ─────────────────────────────────────────────────────────────────

enum PenType {
  fountain('Fountain Pen', Icons.edit),
  pencil('Pencil', Icons.create),
  highlighter('Highlighter', Icons.highlight),
  eraser('Eraser', Icons.auto_fix_normal);

  final String label;
  final IconData icon;
  const PenType(this.label, this.icon);
}

// ─────────────────────────────────────────────────────────────────
// Ink-themed color palette
// ─────────────────────────────────────────────────────────────────

class InkPalette {
  static const List<Color> colors = [
    Color(0xFF1A1A2E), // midnight
    Color(0xFF2C2416), // sepia
    Color(0xFF5C3624), // burnt umber
    Color(0xFF6B1D1D), // mahogany
    Color(0xFF1B4332), // forest ink
    Color(0xFF1A3A5C), // navy ink
    Color(0xFF4A1942), // plum
    Color(0xFF6C5CE7), // violet
    Color(0xFFC0392B), // vermillion
    Color(0xFF2D6A4F), // emerald
  ];

  static const List<String> names = [
    'Midnight',
    'Sepia',
    'Burnt Umber',
    'Mahogany',
    'Forest',
    'Navy',
    'Plum',
    'Violet',
    'Vermillion',
    'Emerald',
  ];
}

// ─────────────────────────────────────────────────────────────────
// Stroke data model
// ─────────────────────────────────────────────────────────────────

class SketchStroke {
  final PenType penType;
  final Color color;
  final double baseWidth;
  final double opacity;
  final List<Offset> points;
  final List<double> velocities;

  SketchStroke({
    required this.penType,
    required this.color,
    required this.baseWidth,
    this.opacity = 1.0,
    List<Offset>? points,
    List<double>? velocities,
  }) : points = points ?? [],
       velocities = velocities ?? [];
}

// ─────────────────────────────────────────────────────────────────
// Main Widget
// ─────────────────────────────────────────────────────────────────

class SketchCanvas extends StatefulWidget {
  final Function(ui.Image) onSave;
  final VoidCallback onCancel;

  const SketchCanvas({super.key, required this.onSave, required this.onCancel});

  @override
  State<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends State<SketchCanvas>
    with TickerProviderStateMixin {
  // Stroke history
  final List<SketchStroke> _strokes = [];
  final List<SketchStroke> _redoStack = [];
  SketchStroke? _currentStroke;

  // Tool settings
  PenType _penType = PenType.fountain;
  Color _color = InkPalette.colors[0];
  double _strokeWidth = 3.0;
  double _opacity = 1.0;

  // UI state
  bool _isToolbarExpanded = false;
  late final AnimationController _toolbarController;
  late final Animation<double> _toolbarAnimation;

  @override
  void initState() {
    super.initState();
    _toolbarController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _toolbarAnimation = CurvedAnimation(
      parent: _toolbarController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _toolbarController.dispose();
    super.dispose();
  }

  // ── Drawing Handlers ─────────────────────────────────────────

  void _onPanStart(DragStartDetails details) {
    if (_penType != PenType.eraser) {
      getIt<SoundService>().playPencilWrite();
    }

    _redoStack.clear();

    setState(() {
      _currentStroke = SketchStroke(
        penType: _penType,
        color: _penType == PenType.eraser ? Colors.white : _color,
        baseWidth: _strokeWidth,
        opacity: _penType == PenType.highlighter ? 0.35 : _opacity,
        points: [details.localPosition],
        velocities: [0.0],
      );
      _strokes.add(_currentStroke!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentStroke == null) return;

    final lastPoint = _currentStroke!.points.last;
    final newPoint = details.localPosition;
    final distance = (newPoint - lastPoint).distance;

    // Don't add points too close together
    if (distance < 1.5) return;

    setState(() {
      _currentStroke!.points.add(newPoint);
      _currentStroke!.velocities.add(distance);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentStroke = null;
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.addAll(_strokes.reversed);
      _strokes.clear();
    });
  }

  Future<void> _exportImage() async {
    final boundary = context.findRenderObject() as RenderBox;
    final size = boundary.size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw paper background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFF5F0E1),
    );

    // Draw strokes
    final painter = _PremiumStrokePainter(strokes: _strokes);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    widget.onSave(img);
  }

  void _toggleToolbar() {
    setState(() => _isToolbarExpanded = !_isToolbarExpanded);
    if (_isToolbarExpanded) {
      _toolbarController.forward();
    } else {
      _toolbarController.reverse();
    }
  }

  // ── Build ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F0E1),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Sketch',
          style: TextStyle(
            fontFamily: 'Caveat',
            fontSize: 24,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            onPressed: _strokes.isNotEmpty ? _undo : null,
            tooltip: 'Undo',
          ),
          IconButton(
            icon: const Icon(Icons.redo),
            onPressed: _redoStack.isNotEmpty ? _redo : null,
            tooltip: 'Redo',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: _strokes.isNotEmpty ? _clear : null,
            tooltip: 'Clear',
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _exportImage,
            tooltip: 'Save',
          ),
        ],
      ),
      body: Stack(
        children: [
          // Paper background
          const Positioned.fill(
            child: ThemedPaper(
              lined: true,
              applyPageStudio: true,
              child: SizedBox.shrink(),
            ),
          ),

          // Drawing canvas
          GestureDetector(
            onPanStart: _onPanStart,
            onPanUpdate: _onPanUpdate,
            onPanEnd: _onPanEnd,
            child: CustomPaint(
              painter: _PremiumStrokePainter(strokes: _strokes),
              size: Size.infinite,
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(child: _buildPremiumToolbar(colorScheme)),
    );
  }

  // ── Premium Toolbar ──────────────────────────────────────────

  Widget _buildPremiumToolbar(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pen type selector row
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  PenType.values.map((pen) {
                    final isSelected = _penType == pen;
                    return GestureDetector(
                      onTap: () => setState(() => _penType = pen),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? colorScheme.primaryContainer
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              pen.icon,
                              size: 22,
                              color:
                                  isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pen.label,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),

          // Expandable color/size controls
          SizeTransition(
            sizeFactor: _toolbarAnimation,
            axisAlignment: -1.0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(
                children: [
                  // Color palette
                  SizedBox(
                    height: 36,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: InkPalette.colors.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 6),
                      itemBuilder: (context, index) {
                        final c = InkPalette.colors[index];
                        final isSelected = c == _color;
                        return GestureDetector(
                          onTap: () => setState(() => _color = c),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: isSelected ? 32 : 28,
                            height: isSelected ? 32 : 28,
                            decoration: BoxDecoration(
                              color: c,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color:
                                    isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow:
                                  isSelected
                                      ? [
                                        BoxShadow(
                                          color: c.withValues(alpha: 0.4),
                                          blurRadius: 8,
                                        ),
                                      ]
                                      : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Stroke width slider
                  Row(
                    children: [
                      Icon(
                        Icons.line_weight,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Slider(
                          value: _strokeWidth,
                          min: 1.0,
                          max: 12.0,
                          divisions: 22,
                          onChanged: (v) => setState(() => _strokeWidth = v),
                        ),
                      ),
                      Text(
                        _strokeWidth.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Opacity slider
                  Row(
                    children: [
                      Icon(
                        Icons.opacity,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      Expanded(
                        child: Slider(
                          value: _opacity,
                          min: 0.1,
                          max: 1.0,
                          divisions: 9,
                          onChanged: (v) => setState(() => _opacity = v),
                        ),
                      ),
                      Text(
                        '${(_opacity * 100).toInt()}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Toggle button
          GestureDetector(
            onTap: _toggleToolbar,
            child: Container(
              padding: const EdgeInsets.only(bottom: 6, top: 2),
              child: AnimatedRotation(
                turns: _isToolbarExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: Icon(
                  Icons.expand_less,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────
// Premium Stroke Painter — Catmull-Rom splines + pen effects
// ─────────────────────────────────────────────────────────────────

class _PremiumStrokePainter extends CustomPainter {
  final List<SketchStroke> strokes;

  _PremiumStrokePainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;

      switch (stroke.penType) {
        case PenType.fountain:
          _drawFountainPen(canvas, stroke);
          break;
        case PenType.pencil:
          _drawPencil(canvas, stroke);
          break;
        case PenType.highlighter:
          _drawHighlighter(canvas, stroke);
          break;
        case PenType.eraser:
          _drawEraser(canvas, stroke);
          break;
      }
    }
  }

  /// Fountain pen: variable width based on velocity + ink pooling at start/stop.
  void _drawFountainPen(Canvas canvas, SketchStroke stroke) {
    final points = stroke.points;
    if (points.length < 2) return;

    for (int i = 0; i < points.length - 1; i++) {
      final velocity =
          i < stroke.velocities.length ? stroke.velocities[i] : 0.0;

      // Slower = thicker (ink pools), faster = thinner
      final width = (stroke.baseWidth * 1.5 - velocity * 0.15).clamp(
        stroke.baseWidth * 0.4,
        stroke.baseWidth * 2.0,
      );

      final paint =
          Paint()
            ..color = stroke.color.withValues(alpha: stroke.opacity)
            ..strokeWidth = width
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      // Use quadratic bezier for smoother lines
      if (i < points.length - 2) {
        final p0 = points[i];
        final p1 = points[i + 1];
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);

        final path =
            Path()
              ..moveTo(p0.dx, p0.dy)
              ..quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
        canvas.drawPath(path, paint);
      } else {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }

    // Ink pool at start point
    if (points.isNotEmpty) {
      canvas.drawCircle(
        points.first,
        stroke.baseWidth * 0.6,
        Paint()
          ..color = stroke.color.withValues(alpha: stroke.opacity * 0.4)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
      );
    }
  }

  /// Pencil: grainy texture using multiple thin lines with jitter.
  void _drawPencil(Canvas canvas, SketchStroke stroke) {
    final random = math.Random(stroke.hashCode);

    for (int i = 0; i < stroke.points.length - 1; i++) {
      final velocity =
          i < stroke.velocities.length ? stroke.velocities[i] : 0.0;
      final width = (stroke.baseWidth - velocity * 0.1).clamp(
        stroke.baseWidth * 0.5,
        stroke.baseWidth * 1.2,
      );

      // Draw 2-3 slightly offset lines for texture
      for (var layer = 0; layer < 3; layer++) {
        final jx = (random.nextDouble() - 0.5) * 1.2;
        final jy = (random.nextDouble() - 0.5) * 1.2;
        final alpha = stroke.opacity * (0.3 + random.nextDouble() * 0.4);

        final paint =
            Paint()
              ..color = stroke.color.withValues(alpha: alpha)
              ..strokeWidth = width * (0.3 + random.nextDouble() * 0.4)
              ..strokeCap = StrokeCap.round
              ..style = PaintingStyle.stroke;

        canvas.drawLine(
          stroke.points[i] + Offset(jx, jy),
          stroke.points[i + 1] + Offset(jx, jy),
          paint,
        );
      }
    }
  }

  /// Highlighter: wide, semi-transparent, flat cap.
  void _drawHighlighter(Canvas canvas, SketchStroke stroke) {
    if (stroke.points.length < 2) return;

    final path = Path()..moveTo(stroke.points[0].dx, stroke.points[0].dy);

    for (int i = 1; i < stroke.points.length; i++) {
      final prev = stroke.points[i - 1];
      final curr = stroke.points[i];
      final mid = Offset((prev.dx + curr.dx) / 2, (prev.dy + curr.dy) / 2);
      path.quadraticBezierTo(prev.dx, prev.dy, mid.dx, mid.dy);
    }
    path.lineTo(stroke.points.last.dx, stroke.points.last.dy);

    canvas.drawPath(
      path,
      Paint()
        ..color = stroke.color.withValues(alpha: 0.25)
        ..strokeWidth = stroke.baseWidth * 4
        ..strokeCap = StrokeCap.square
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.multiply,
    );
  }

  /// Eraser: white strokes.
  void _drawEraser(Canvas canvas, SketchStroke stroke) {
    if (stroke.points.length < 2) return;

    final path = Path()..moveTo(stroke.points[0].dx, stroke.points[0].dy);
    for (int i = 1; i < stroke.points.length; i++) {
      path.lineTo(stroke.points[i].dx, stroke.points[i].dy);
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFF5F0E1) // paper color
        ..strokeWidth = stroke.baseWidth * 3
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke
        ..blendMode = BlendMode.srcOver,
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumStrokePainter oldDelegate) => true;
}
