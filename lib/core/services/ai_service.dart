import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

import '../constants/app_constants.dart';

/// Model bilgisi ve durumu
class ModelInfo {
  final String id;
  final String displayName;
  final String description;
  final bool isFreeTier;
  final int? quotaLimit;

  const ModelInfo({
    required this.id,
    required this.displayName,
    required this.description,
    this.isFreeTier = true,
    this.quotaLimit,
  });
}

/// AI servisi durumu
class AiServiceStatus {
  final bool isConfigured;
  final String? selectedModel;
  final String? lastError;
  final int? remainingQuota;
  final DateTime? quotaResetTime;
  final List<String> availableModels;

  AiServiceStatus({
    required this.isConfigured,
    this.selectedModel,
    this.lastError,
    this.remainingQuota,
    this.quotaResetTime,
    this.availableModels = const [],
  });
}

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

  /// Gets current AI service status.
  Future<AiServiceStatus> getStatus();

  /// Sets the AI model to use.
  Future<void> setModel(String modelId);

  /// Gets currently selected model.
  String get selectedModel;

  /// List of available models.
  List<ModelInfo> get availableModels;

  /// Debug method to list available models for the apiKey.
  Future<List<String>> listAvailableModels();

  /// Gets quota information if available.
  Future<Map<String, dynamic>?> getQuotaInfo();
}

@LazySingleton(as: AiService)
class GeminiAiService implements AiService {
  final SharedPreferences _prefs;

  GeminiAiService(this._prefs);

  static const String _promptBase =
      "You are a helpful writing assistant for a premium journal app called Rojnivis. The user is writing in a private, luxury digital notebook. Keep the tone elegant, introspective, and helpful.";

  /// Güncel ve metin üretimi için güvenli model seçenekleri.
  static const List<ModelInfo> _models = [
    ModelInfo(
      id: 'gemini-2.5-flash-lite',
      displayName: 'Gemini 2.5 Flash-Lite',
      description: 'En hızlı ve düşük maliyetli',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Hızlı ve dengeli',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      description: 'En yüksek kalite ve muhakeme',
      isFreeTier: true,
    ),
  ];

  /// Seçili modelden başlayıp diğer modellere düşen sıra.
  List<ModelInfo> get _quotaFriendlyModels {
    final current = selectedModel;
    return [
      ..._models.where((m) => m.id == current),
      ..._models.where((m) => m.id != current),
    ];
  }

  String get _storageKey => StorageKeys.aiModel;

  @override
  String get selectedModel {
    final stored = _prefs.getString(_storageKey);
    // Validate stored model exists in current list, otherwise default to first
    if (stored != null && _models.any((m) => m.id == stored)) {
      return stored;
    }
    return _models.first.id;
  }

  @override
  List<ModelInfo> get availableModels => _models;

  @override
  Future<void> setModel(String modelId) async {
    await _prefs.setString(_storageKey, modelId);
  }

  GenerativeModel? _getModel({String? overrideModel}) {
    final apiKey = _prefs.getString('ai_api_key');
    if (apiKey == null || apiKey.isEmpty) return null;

    final modelId = overrideModel ?? selectedModel;
    return GenerativeModel(model: modelId, apiKey: apiKey);
  }

  @override
  bool get isConfigured => _prefs.getString('ai_api_key')?.isNotEmpty ?? false;

  @override
  Future<AiServiceStatus> getStatus() async {
    if (!isConfigured) {
      return AiServiceStatus(isConfigured: false);
    }

    final availableModels = await listAvailableModels();
    final quotaInfo = await getQuotaInfo();

    return AiServiceStatus(
      isConfigured: true,
      selectedModel: selectedModel,
      availableModels:
          availableModels.where((m) => !m.contains('Error')).toList(),
      remainingQuota: quotaInfo?['remaining'] as int?,
      quotaResetTime:
          quotaInfo?['resetTime'] != null
              ? DateTime.tryParse(quotaInfo!['resetTime'] as String)
              : null,
    );
  }

  bool _isFallbackWorthyError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('429') ||
        msg.contains('quota') ||
        msg.contains('rate limit') ||
        msg.contains('resource exhausted') ||
        msg.contains('503') ||
        msg.contains('unavailable') ||
        msg.contains('404') ||
        msg.contains('not found');
  }

  Future<({GenerateContentResponse? response, String? error, String modelId})>
  _generateContentWithFallback(
    List<Content> prompt, {
    GenerationConfig? generationConfig,
  }) async {
    final model = _getModel();
    if (model == null) {
      return (response: null, error: 'API Key not configured', modelId: '');
    }

    Object? lastError;

    for (int index = 0; index < _quotaFriendlyModels.length; index++) {
      final candidate = _quotaFriendlyModels[index];
      final candidateModel = _getModel(overrideModel: candidate.id);
      if (candidateModel == null) {
        continue;
      }

      try {
        final response = await candidateModel.generateContent(
          prompt,
          generationConfig: generationConfig,
        );

        if (candidate.id != selectedModel) {
          await setModel(candidate.id);
          debugPrint('Auto-switched to fallback model: ${candidate.id}');
        }

        return (response: response, error: null, modelId: candidate.id);
      } catch (e) {
        lastError = e;
        debugPrint('Model ${candidate.id} failed: $e');

        final isLastAttempt = index == _quotaFriendlyModels.length - 1;
        if (!_isFallbackWorthyError(e) || isLastAttempt) {
          break;
        }
      }
    }

    return (response: null, error: lastError?.toString(), modelId: '');
  }

  @override
  Future<String> summarize(String text) async {
    final prompt = [
      Content.text(
        "$_promptBase\n\nPlease provide a concise, elegant summary (max 2 sentences) of the following journal entry:\n\n$text",
      ),
    ];

    try {
      final result = await _generateContentWithFallback(prompt);
      if (result.response == null) {
        return "Hata: ${_handleError(result.error ?? 'Model oluşturulamadı')}";
      }
      return result.response!.text ?? "Could not generate summary.";
    } catch (e) {
      debugPrint('AI Service Error (Summarize): $e');
      return _handleError(e);
    }
  }

  @override
  Future<String> continueWriting(String text, {String? context}) async {
    final contextPart =
        context != null ? "Context about the day: $context\n" : "";
    final prompt = [
      Content.text(
        "$_promptBase\n${contextPart}Existing text: $text\n\nPlease continue the writing naturally, maintaining the user's style. Provide only the continuation text, max 3-4 sentences.",
      ),
    ];

    try {
      final result = await _generateContentWithFallback(prompt);
      if (result.response == null) {
        return "[Hata: ${_handleError(result.error ?? 'AI şuanda kullanılamıyor')}]";
      }
      return result.response!.text ?? "";
    } catch (e) {
      debugPrint('AI Service Error (Continue): $e');
      return "[Hata: ${_handleError(e)}]";
    }
  }

  @override
  Future<List<String>> generateTags(String text) async {
    final prompt = [
      Content.text(
        "$_promptBase\nText: $text\n\nSuggest 3-5 relevant hashtags/tags for this entry. Provide only the tags separated by commas, no introductory text.",
      ),
    ];

    try {
      final result = await _generateContentWithFallback(prompt);
      final tagsRaw = result.response?.text ?? "";
      if (tagsRaw.isEmpty) {
        return [];
      }
      return tagsRaw
          .split(',')
          .map((e) => e.trim().replaceAll('#', ''))
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      debugPrint('AI Service Error (Tags): $e');
      return [];
    }
  }

  String _handleError(dynamic error) {
    final errorStr = error.toString();
    final lowered = errorStr.toLowerCase();

    if (lowered.contains('403') ||
        lowered.contains('api key') ||
        lowered.contains('permission')) {
      return 'Geçersiz API Anahtarı. Ayarlar > AI Asistan bölümünü kontrol edin.';
    }
    if (lowered.contains('404') || lowered.contains('not found')) {
      return 'AI modeli bulunamadı. Ayarlar > AI Model bölümünden güncel bir model seçin.';
    }
    if (lowered.contains('429') ||
        lowered.contains('quota') ||
        lowered.contains('rate limit') ||
        lowered.contains('resource exhausted')) {
      return 'API kotası veya hız limiti aşıldı. Birkaç dakika bekleyip tekrar deneyin.';
    }
    if (lowered.contains('timeout') || lowered.contains('deadline')) {
      return 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
    }
    return 'AI hatası: ${errorStr.substring(0, errorStr.length > 100 ? 100 : errorStr.length)}';
  }

  @override
  Future<List<String>> listAvailableModels() async {
    final apiKey = _prefs.getString('ai_api_key');
    if (apiKey == null || apiKey.isEmpty) return ['API Key not configured'];

    final selected = selectedModelInfo;
    try {
      final model = GenerativeModel(model: selected.id, apiKey: apiKey);
      await model.generateContent([
        Content.text('ok'),
      ], generationConfig: GenerationConfig(maxOutputTokens: 1));

      return [
        '${selected.displayName} ✓',
        ..._models
            .where((m) => m.id != selected.id)
            .map((m) => '${m.displayName} (hazır)'),
      ];
    } catch (e) {
      return [
        '${selected.displayName}: ${_handleError(e)}',
        ..._models
            .where((m) => m.id != selected.id)
            .map((m) => '${m.displayName} (alternatif)'),
      ];
    }
  }

  @override
  Future<Map<String, dynamic>?> getQuotaInfo() async {
    // Google Gemini API does not provide quota info programmatically.
    // We return null to hide the quota UI.
    return null;
  }

  ModelInfo get selectedModelInfo {
    return _models.firstWhere(
      (m) => m.id == selectedModel,
      orElse: () => _quotaFriendlyModels.first,
    );
  }

  /// Her AI isteğinde çağrılması gereken metod
  // Future<void> _incrementRequestCount() async {
  //   final requestCountKey = 'ai_daily_request_count';
  //   final lastRequestKey = 'ai_last_request_time';
  //   final now = DateTime.now();

  //   final currentCount = _prefs.getInt(requestCountKey) ?? 0;
  //   await _prefs.setInt(requestCountKey, currentCount + 1);
  //   await _prefs.setString(lastRequestKey, now.toIso8601String());
  // }
}
