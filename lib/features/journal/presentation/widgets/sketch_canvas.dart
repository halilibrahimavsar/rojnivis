import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../../../di/injection.dart';
import '../../../../core/services/sound_service.dart';

class SketchCanvas extends StatefulWidget {
  final Function(ui.Image) onSave;
  final VoidCallback onCancel;

  const SketchCanvas({super.key, required this.onSave, required this.onCancel});

  @override
  State<SketchCanvas> createState() => _SketchCanvasState();
}

class _SketchCanvasState extends State<SketchCanvas> {
  final List<SketchPath> _paths = [];
  SketchPath? _currentPath;
  Color _currentColor = Colors.black87;

  void _onPanStart(DragStartDetails details) {
    getIt<SoundService>().playPencilWrite();
    setState(() {
      _currentPath = SketchPath(
        color: _currentColor,
        points: [details.localPosition],
        velocities: [0.0],
      );
      _paths.add(_currentPath!);
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_currentPath == null) return;

    final lastPoint = _currentPath!.points.last;
    final newPoint = details.localPosition;
    final distance = (newPoint - lastPoint).distance;

    // Simple velocity estimation
    final velocity = distance;

    setState(() {
      _currentPath!.points.add(newPoint);
      _currentPath!.velocities.add(velocity);
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _currentPath = null;
  }

  Future<void> _exportImage() async {
    final boundary = context.findRenderObject() as RenderBox;
    final size = boundary.size;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Draw white background
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.white,
    );

    // Draw paths
    final painter = SketchPainter(paths: _paths);
    painter.paint(canvas, size);

    final picture = recorder.endRecording();
    final img = await picture.toImage(size.width.toInt(), size.height.toInt());
    widget.onSave(img);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Sketch'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: widget.onCancel,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_outlined),
            onPressed: () => setState(() => _paths.clear()),
          ),
          IconButton(icon: const Icon(Icons.check), onPressed: _exportImage),
        ],
      ),
      body: GestureDetector(
        onPanStart: _onPanStart,
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: CustomPaint(
          painter: SketchPainter(paths: _paths),
          size: Size.infinite,
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ColorBtn(
                Colors.black87,
                _currentColor,
                (c) => setState(() => _currentColor = c),
              ),
              _ColorBtn(
                Colors.blueGrey,
                _currentColor,
                (c) => setState(() => _currentColor = c),
              ),
              _ColorBtn(
                Colors.brown,
                _currentColor,
                (c) => setState(() => _currentColor = c),
              ),
              _ColorBtn(
                Colors.indigo,
                _currentColor,
                (c) => setState(() => _currentColor = c),
              ),
              _ColorBtn(
                Colors.redAccent,
                _currentColor,
                (c) => setState(() => _currentColor = c),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SketchPath {
  final Color color;
  final List<Offset> points;
  final List<double> velocities;

  SketchPath({
    required this.color,
    required this.points,
    required this.velocities,
  });
}

class SketchPainter extends CustomPainter {
  final List<SketchPath> paths;

  SketchPainter({required this.paths});

  @override
  void paint(Canvas canvas, Size size) {
    for (final path in paths) {
      if (path.points.isEmpty) continue;

      final paint =
          Paint()
            ..color = path.color
            ..strokeCap = StrokeCap.round
            ..style = PaintingStyle.stroke;

      for (int i = 0; i < path.points.length - 1; i++) {
        final velocity = path.velocities[i];
        // Slower = thicker, Faster = thinner (pencil logic)
        final strokeWidth = (4.0 - (velocity * 0.2)).clamp(1.0, 5.0);

        paint.strokeWidth = strokeWidth;
        canvas.drawLine(path.points[i], path.points[i + 1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant SketchPainter oldDelegate) => true;
}

class _ColorBtn extends StatelessWidget {
  final Color color;
  final Color current;
  final ValueChanged<Color> onSelect;

  const _ColorBtn(this.color, this.current, this.onSelect);

  @override
  Widget build(BuildContext context) {
    final isSelected = color == current;
    return GestureDetector(
      onTap: () => onSelect(color),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? Colors.grey : Colors.transparent,
            width: 2,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ]
                  : [],
        ),
      ),
    );
  }
}
