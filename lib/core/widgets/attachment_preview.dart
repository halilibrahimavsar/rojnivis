import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

Future<void> openAttachment(BuildContext context, String path) async {
  if (path.isEmpty) return;
  final file = File(path);
  if (!file.existsSync()) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('file_not_found'.tr())));
    return;
  }

  final lower = path.toLowerCase();
  if (isImagePath(lower)) {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      builder:
          (context) => GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Center(
              child: InteractiveViewer(
                child: Image.file(file, fit: BoxFit.contain),
              ),
            ),
          ),
    );
    return;
  }

  if (isAudioPath(lower)) {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _AudioPlayerSheet(path: path),
    );
    return;
  }

  await OpenFilex.open(path);
}

bool isImagePath(String path) {
  final lower = path.toLowerCase();
  return _isImage(lower);
}

bool isAudioPath(String path) {
  final lower = path.toLowerCase();
  return _isAudio(lower);
}

bool _isImage(String lower) =>
    lower.endsWith('.png') ||
    lower.endsWith('.jpg') ||
    lower.endsWith('.jpeg') ||
    lower.endsWith('.webp');

bool _isAudio(String lower) =>
    lower.endsWith('.m4a') ||
    lower.endsWith('.aac') ||
    lower.endsWith('.mp3') ||
    lower.endsWith('.wav') ||
    lower.endsWith('.ogg');

class _AudioPlayerSheet extends StatefulWidget {
  const _AudioPlayerSheet({required this.path});

  final String path;

  @override
  State<_AudioPlayerSheet> createState() => _AudioPlayerSheetState();
}

class _AudioPlayerSheetState extends State<_AudioPlayerSheet> {
  late final AudioPlayer _player;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  PlayerState _state = PlayerState.stopped;
  late final List<double> _bars;
  double _speed = 1.0;

  @override
  void initState() {
    super.initState();
    _player = AudioPlayer();
    _bars = List.generate(
      40,
      (index) => 0.2 + Random(index * 7).nextDouble() * 0.8,
    );
    _player.onDurationChanged.listen((value) {
      setState(() => _duration = value);
    });
    _player.onPositionChanged.listen((value) {
      setState(() => _position = value);
    });
    _player.onPlayerStateChanged.listen((value) {
      setState(() => _state = value);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_state == PlayerState.playing) {
      await _player.pause();
      return;
    }
    await _player.play(DeviceFileSource(widget.path), position: _position);
  }

  Future<void> _setSpeed(double speed) async {
    await _player.setPlaybackRate(speed);
    setState(() => _speed = speed);
  }

  String _formatDuration(Duration duration) {
    final totalSeconds = duration.inSeconds;
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _fileName(String path) {
    final normalized = path.replaceAll('\\', '/');
    return normalized.split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final durationMs = _duration.inMilliseconds;
    final hasDuration = durationMs > 0;
    final max = hasDuration ? durationMs.toDouble() : 1.0;
    final value =
        _position.inMilliseconds
            .clamp(0, hasDuration ? durationMs : 1)
            .toDouble();
    final progress = value / max;
    final formatted = _formatDuration(_position);
    final total = _formatDuration(_duration);
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _fileName(widget.path),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 64,
            child: CustomPaint(
              painter: _WaveformPainter(
                bars: _bars,
                progress: progress,
                activeColor: colors.primary,
                inactiveColor: colors.primary.withValues(alpha: 0.2),
              ),
              child: const SizedBox.expand(),
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: _toggle,
                icon: Icon(
                  _state == PlayerState.playing
                      ? Icons.pause
                      : Icons.play_arrow,
                ),
              ),
              Expanded(
                child: Slider(
                  value: value,
                  min: 0,
                  max: max,
                  onChanged:
                      hasDuration
                          ? (next) {
                            _player.seek(Duration(milliseconds: next.toInt()));
                          }
                          : null,
                ),
              ),
              Text(formatted),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                total,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
              Wrap(
                spacing: 6,
                children: [
                  for (final speed in const [0.5, 1.0, 1.25, 1.5, 2.0])
                    ChoiceChip(
                      label: Text('${speed}x'),
                      selected: _speed == speed,
                      onSelected: (_) => _setSpeed(speed),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
  });

  final List<double> bars;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / (bars.length * 1.4);
    final gap = barWidth * 0.4;
    final activeBars = (bars.length * progress).floor();
    final centerY = size.height / 2;

    for (int i = 0; i < bars.length; i++) {
      final height = bars[i] * size.height;
      final x = i * (barWidth + gap);
      final rect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(x + barWidth / 2, centerY),
          width: barWidth,
          height: height,
        ),
        const Radius.circular(6),
      );
      final paint =
          Paint()..color = i <= activeBars ? activeColor : inactiveColor;
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
