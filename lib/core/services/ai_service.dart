import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

/// Abstraction for AI-powered writing assistance.
abstract class AiService {
  /// Generates a summary of the given text.
  Future<String> summarize(String text);

  /// Suggests a continuation of the writing based on context.
  Future<String> continueWriting(String text, {String? context});

  /// Generates suggested tags based on content.
  Future<List<String>> generateTags(String text);

  /// Checks if AI service is configured (API key exists).
  bool get isConfigured;

  /// Debug method to list available models for the apiKey.
  Future<List<String>> listAvailableModels();
}

@LazySingleton(as: AiService)
class GeminiAiService implements AiService {
  final SharedPreferences _prefs;

  GeminiAiService(this._prefs);

  static const String _promptBase =
      "You are a helpful writing assistant for a premium journal app called Rojnivis. The user is writing in a private, luxury digital notebook. Keep the tone elegant, introspective, and helpful.";

  GenerativeModel? _getModel() {
    final apiKey = _prefs.getString('ai_api_key');
    if (apiKey == null || apiKey.isEmpty) return null;

    return GenerativeModel(model: 'gemini-2.0-flash', apiKey: apiKey);
  }

  @override
  bool get isConfigured => _prefs.getString('ai_api_key')?.isNotEmpty ?? false;

  @override
  Future<String> summarize(String text) async {
    final model = _getModel();
    if (model == null)
      return "AI not configured. Please add API key in settings.";

    final prompt = [
      Content.text(
        "$_promptBase\n\nPlease provide a concise, elegant summary (max 2 sentences) of the following journal entry:\n\n$text",
      ),
    ];

    try {
      final response = await model.generateContent(prompt);
      return response.text ?? "Could not generate summary.";
    } catch (e) {
      debugPrint('AI Service Error (Summarize): $e');
      final errorStr = e.toString();

      if (errorStr.contains('403') ||
          errorStr.contains('API key') ||
          errorStr.contains('permission')) {
        throw 'Invalid API Key. Please check your API key in Settings > AI Assistant.';
      }
      if (errorStr.contains('404') || errorStr.contains('not found')) {
        throw 'AI model not available. Please try again later.';
      }
      if (errorStr.contains('429') ||
          errorStr.contains('quota') ||
          errorStr.contains('rate limit')) {
        throw 'API quota exceeded. Please wait a moment and try again.';
      }
      if (errorStr.contains('timeout') || errorStr.contains('deadline')) {
        throw 'Request timed out. Please check your internet connection.';
      }
      throw 'AI service error: ${errorStr.substring(0, errorStr.length > 100 ? 100 : errorStr.length)}';
    }
  }

  @override
  Future<String> continueWriting(String text, {String? context}) async {
    final model = _getModel();
    if (model == null) return "AI not configured.";

    final contextPart =
        context != null ? "Context about the day: $context\n" : "";
    final prompt = [
      Content.text(
        "$_promptBase\n${contextPart}Existing text: $text\n\nPlease continue the writing naturally, maintaining the user's style. Provide only the continuation text, max 3-4 sentences.",
      ),
    ];

    try {
      final response = await model.generateContent(prompt);
      return response.text ?? "";
    } catch (e) {
      debugPrint('AI Service Error (Continue): $e');
      // Return user-friendly error message instead of empty string
      final errorStr = e.toString();
      if (errorStr.contains('403') || errorStr.contains('API key')) {
        return "[Error: Invalid API Key. Please check Settings > AI Assistant.]";
      }
      if (errorStr.contains('429') || errorStr.contains('quota')) {
        return "[Error: API quota exceeded. Please try again later.]";
      }
      return "[Error: Could not generate continuation. Please try again.]";
    }
  }

  @override
  Future<List<String>> generateTags(String text) async {
    final model = _getModel();
    if (model == null) return [];

    final prompt = [
      Content.text(
        "$_promptBase\nText: $text\n\nSuggest 3-5 relevant hashtags/tags for this entry. Provide only the tags separated by commas, no introductory text.",
      ),
    ];

    try {
      final response = await model.generateContent(prompt);
      final tagsRaw = response.text ?? "";
      return tagsRaw
          .split(',')
          .map((e) => e.trim().replaceAll('#', ''))
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('AI Service Error (Tags): $e');
      // Return empty list but show error via debugPrint
      return [];
    }
  }

  @override
  Future<List<String>> listAvailableModels() async {
    final apiKey = _prefs.getString('ai_api_key');
    if (apiKey == null || apiKey.isEmpty) return ['API Key not configured'];

    // We can't easily list models with the high-level GenerativeModel class
    // but we can try to initialize a model and see if it throws immediately
    // or if there is a listModels equivalent in the library.
    // The google_generative_ai package doesn't expose listModels easily in the minimal API.
    // Instead, let's try a simple prompt on a few known model names to see which works.

    final modelsToTest = [
      'gemini-2.5-flash',
      'gemini-2.5-pro',
      'gemini-2.0-flash',
      'gemini-2.0-flash-001',
      'gemini-2.0-flash-lite',
      'gemini-2.0-flash-lite-001',
      'gemini-flash-latest',
      'gemini-pro-latest',
    ];
    final available = <String>[];
    final errors = <String>[];

    for (final modelName in modelsToTest) {
      try {
        final model = GenerativeModel(model: modelName, apiKey: apiKey);
        await model.generateContent([Content.text('Test')]);
        available.add(modelName);
      } catch (e) {
        // More descriptive error message
        String errorMsg = e.toString();
        if (errorMsg.contains('404') || errorMsg.contains('not found')) {
          errorMsg = 'Model not found (404)';
        } else if (errorMsg.contains('403')) {
          errorMsg = 'Permission denied (403) - Check API Key';
        } else if (errorMsg.contains('429')) {
          errorMsg = 'Quota exceeded (429)';
        }
        errors.add('$modelName: $errorMsg');
      }
    }

    if (available.isEmpty) {
      return ['No working models found.', ...errors];
    }
    return available;
  }
}
