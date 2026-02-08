import 'dart:async';
import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class AudioRecorderWidget extends StatefulWidget {
  final Function(String path) onRecordingComplete;

  const AudioRecorderWidget({super.key, required this.onRecordingComplete});

  @override
  State<AudioRecorderWidget> createState() => _AudioRecorderWidgetState();
}

class _AudioRecorderWidgetState extends State<AudioRecorderWidget> {
  late final AudioRecorder _audioRecorder;
  bool _isRecording = false;
  Timer? _timer;
  int _recordDuration = 0;

  @override
  void initState() {
    super.initState();
    _audioRecorder = AudioRecorder();
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = '${directory.path}/audio_${const Uuid().v4()}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
        });

        _startTimer();
      }
    } catch (e) {
      debugPrint('Error starting recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();

      _timer?.cancel();
      setState(() {
        _isRecording = false;
        _recordDuration = 0;
      });

      if (path != null) {
        widget.onRecordingComplete(path);
      }
    } catch (e) {
      debugPrint('Error stopping recording: $e');
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() => _recordDuration++);
    });
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(_isRecording ? Icons.stop : Icons.mic),
          color: _isRecording ? Colors.red : Theme.of(context).primaryColor,
          onPressed: _isRecording ? _stopRecording : _startRecording,
        ),
        if (_isRecording)
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              _formatDuration(_recordDuration),
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
      ],
    );
  }
}
