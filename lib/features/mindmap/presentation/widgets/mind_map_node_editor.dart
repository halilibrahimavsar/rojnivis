import 'package:flutter/material.dart';

class MindMapNodeEditor extends StatefulWidget {
  final String initialText;
  final String title;
  final String buttonText;
  final Function(String) onSubmit;

  const MindMapNodeEditor({
    super.key,
    required this.initialText,
    required this.title,
    required this.buttonText,
    required this.onSubmit,
  });

  @override
  State<MindMapNodeEditor> createState() => _MindMapNodeEditorState();
}

class _MindMapNodeEditorState extends State<MindMapNodeEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_controller.text.trim().isNotEmpty) {
      widget.onSubmit(_controller.text.trim());
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(
          labelText: 'Node label',
          border: const OutlineInputBorder(),
        ),
        onSubmitted: (_) => _handleSubmit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _handleSubmit, child: Text(widget.buttonText)),
      ],
    );
  }
}
