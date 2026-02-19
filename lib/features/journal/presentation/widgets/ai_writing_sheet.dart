import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/themed_paper.dart';

/// A bottom sheet that shows AI writing suggestions with a typewriter effect.
class AiWritingSheet extends StatefulWidget {
  final Future<String> suggestionFuture;
  final Function(String) onAccept;

  const AiWritingSheet({
    super.key,
    required this.suggestionFuture,
    required this.onAccept,
  });

  @override
  State<AiWritingSheet> createState() => _AiWritingSheetState();
}

class _AiWritingSheetState extends State<AiWritingSheet>
    with SingleTickerProviderStateMixin {
  String _displayedText = "";
  String _fullText = "";
  bool _isTyping = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchSuggestion();
  }

  Future<void> _fetchSuggestion() async {
    setState(() {
      _isTyping = true;
      _hasError = false;
    });

    try {
      _fullText = await widget.suggestionFuture;
      _startTypewriter();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _hasError = true;
        });
      }
    }
  }

  void _startTypewriter() async {
    for (int i = 0; i <= _fullText.length; i++) {
      if (!mounted) return;
      setState(() {
        _displayedText = _fullText.substring(0, i);
      });
      await Future.delayed(const Duration(milliseconds: 20));
    }
    if (mounted) {
      setState(() {
        _isTyping = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedPaper(
      padding: const EdgeInsets.all(24),
      applyPageStudio: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.amber),
              const SizedBox(width: 8),
              Text(
                'ai_write_suggestion'.tr(),
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (_isTyping)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: SingleChildScrollView(
              child: Text(
                _displayedText.isEmpty && !_hasError && !_isTyping
                    ? "..."
                    : _displayedText,
                style: const TextStyle(
                  fontFamily: 'Caveat',
                  fontSize: 18,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
          if (_hasError)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'ai_error'.tr(),
                style: TextStyle(color: colorScheme.error, fontSize: 12),
              ),
            ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('cancel'.tr()),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed:
                    _isTyping || _displayedText.isEmpty
                        ? null
                        : () {
                          widget.onAccept(_fullText);
                          Navigator.pop(context);
                        },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
                child: Text('use_suggestion'.tr()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
