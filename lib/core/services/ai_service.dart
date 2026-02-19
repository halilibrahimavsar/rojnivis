import 'package:firebase_remote_config/firebase_remote_config.dart';
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

  /// Initialize the service (fetch remote config)
  Future<void> init();
}

@LazySingleton(as: AiService)
class GeminiAiService implements AiService {
  final SharedPreferences _prefs;
  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  GeminiAiService(this._prefs);

  static const String _promptBase =
      "You are a helpful writing assistant for a premium journal app called Rojnivis. The user is writing in a private, luxury digital notebook. Keep the tone elegant, introspective, and helpful.";

  /// Güncel ve metin üretimi için güvenli model seçenekleri.
  static const List<ModelInfo> _models = [
    ModelInfo(
      id: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Hızlı ve yetenekli (Önerilen)',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-2.0-flash-lite',
      displayName: 'Gemini 2.0 Flash Lite',
      description: 'Çok hızlı, hafif model',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-2.0-flash-001',
      displayName: 'Gemini 2.0 Flash 001',
      description: 'Kararlı 2.0 Flash sürümü',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'Gelişmiş 2.5 Flash modeli',
      isFreeTier: true,
    ),
    ModelInfo(
      id: 'gemini-3-flash-preview',
      displayName: 'Gemini 3 Flash (Preview)',
      description: 'Deneysel 3.0 Flash modeli',
      isFreeTier: true,
    ),
  ];

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

  @override
  Future<void> init() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(minutes: 1),
          minimumFetchInterval: const Duration(hours: 12),
        ),
      );

      // Set default values
      await _remoteConfig.setDefaults(const {'gemini_api_key': ''});

      await _remoteConfig.fetchAndActivate();
      debugPrint('Remote Config fetched. API Key configured: $isConfigured');

      // If configured, run a quick check to see if the default model works
      if (isConfigured) {
        _checkAndHealModelSelection();
      }
    } catch (e) {
      debugPrint('Failed to fetch remote config: $e');
    }
  }

  /// Tries to use the selected model. If it fails, finds the first working model and switches to it.
  Future<void> _checkAndHealModelSelection() async {
    try {
      // Check current model
      final currentModel = _getModel();
      if (currentModel == null) return;

      await currentModel.generateContent([
        Content.text('ping'),
      ], generationConfig: GenerationConfig(maxOutputTokens: 1));
    } catch (e) {
      debugPrint(
        'Current model $selectedModel failed ping: $e. Searching for working model...',
      );
      // Current model failed, try others
      for (final model in _models) {
        if (model.id == selectedModel) continue;

        try {
          final candidate = _getModel(overrideModel: model.id);
          if (candidate != null) {
            await candidate.generateContent([
              Content.text('ping'),
            ], generationConfig: GenerationConfig(maxOutputTokens: 1));
            // Verify success
            await setModel(model.id);
            debugPrint('Switched to working model: ${model.id}');
            return;
          }
        } catch (_) {}
      }
    }
  }

  GenerativeModel? _getModel({String? overrideModel}) {
    final apiKey = _remoteConfig.getString('gemini_api_key');
    if (apiKey.isEmpty) return null;

    final modelId = overrideModel ?? selectedModel;
    return GenerativeModel(model: modelId, apiKey: apiKey);
  }

  @override
  bool get isConfigured => _remoteConfig.getString('gemini_api_key').isNotEmpty;

  @override
  Future<AiServiceStatus> getStatus() async {
    // Try to fetch latest config when checking status
    try {
      await _remoteConfig.fetchAndActivate();
    } catch (_) {}

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
      // Try to fetch config one more time if key is missing
      await init();
      if (_getModel() == null) {
        return (
          response: null,
          error: 'API Key not configured in Remote Config',
          modelId: '',
        );
      }
    }

    // Prioritize selected model, then try others
    final candidateModels = [
      _models.firstWhere((m) => m.id == selectedModel),
      ..._models.where((m) => m.id != selectedModel),
    ];

    Object? lastError;

    for (int index = 0; index < candidateModels.length; index++) {
      final candidate = candidateModels[index];
      final candidateModel = _getModel(overrideModel: candidate.id);
      if (candidateModel == null) continue;

      try {
        final response = await candidateModel.generateContent(
          prompt,
          generationConfig: generationConfig,
        );

        // If we succeeded with a different model than selected, maybe update preference?
        // For now, let's just use it without changing user preference permanently unless 'init' healing logic runs.
        return (response: response, error: null, modelId: candidate.id);
      } catch (e) {
        lastError = e;
        debugPrint('Model ${candidate.id} failed: $e');

        final isLastAttempt = index == candidateModels.length - 1;
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
    var errorStr = error.toString();

    // Extract inner message from some wrapper exceptions if possible
    if (errorStr.contains('GenerativeAIException')) {
      errorStr = errorStr.replaceAll('GenerativeAIException: ', '');
    }

    final lowered = errorStr.toLowerCase();

    if (lowered.contains('403') ||
        lowered.contains('api key') ||
        lowered.contains('permission')) {
      return 'Geçersiz API Anahtarı. Remote Config ayarlarını kontrol edin.';
    }
    if (lowered.contains('404') || lowered.contains('not found')) {
      return 'AI modeli bulunamadı. Lütfen daha yeni bir model seçin.';
    }
    if (lowered.contains('429') ||
        lowered.contains('quota') ||
        lowered.contains('rate limit') ||
        lowered.contains('resource exhausted')) {
      return 'API kotası aşıldı. Lütfen biraz bekleyin.';
    }
    if (lowered.contains('timeout') || lowered.contains('deadline')) {
      return 'Zaman aşımı. İnternet bağlantınızı kontrol edin.';
    }
    return 'Hata: ${errorStr.length > 80 ? '${errorStr.substring(0, 80)}...' : errorStr}';
  }

  @override
  Future<List<String>> listAvailableModels() async {
    final apiKey = _remoteConfig.getString('gemini_api_key');

    if (apiKey.isEmpty) {
      // Try to fetch one more time urgently
      await _remoteConfig.fetchAndActivate();
      if (_remoteConfig.getString('gemini_api_key').isEmpty) {
        return ['API Key not configured in Remote Config (Empty)'];
      }
    }

    // Effective API Key
    final effectiveApiKey = _remoteConfig.getString('gemini_api_key');
    final maskedKey =
        effectiveApiKey.length > 4
            ? '${effectiveApiKey.substring(0, 4)}...${effectiveApiKey.substring(effectiveApiKey.length - 4)}'
            : 'Invalid Key';

    List<String> results = [];
    List<String> errors = [];

    for (final modelInfo in _models) {
      try {
        final model = GenerativeModel(
          model: modelInfo.id,
          apiKey: effectiveApiKey,
        );
        // Quick ping to check if model is actually accessible with this key
        await model.generateContent([
          Content.text('test'),
        ], generationConfig: GenerationConfig(maxOutputTokens: 1));

        final isSelected = modelInfo.id == selectedModel;
        results.add(
          '${modelInfo.displayName} ${isSelected ? '(Seçili) ✓' : ''}',
        );
      } catch (e) {
        final err = e.toString();
        final cleanErr =
            err.contains('GenerativeAIException')
                ? err.replaceAll('GenerativeAIException: ', '')
                : err;

        debugPrint('Model check failed for ${modelInfo.id}: $e');
        errors.add(
          '${modelInfo.displayName}: ${cleanErr.length > 50 ? '${cleanErr.substring(0, 50)}...' : cleanErr}',
        );
      }
    }

    if (results.isEmpty) {
      return [
        'Hata: Hiçbir model çalışmadı.',
        'API Key: $maskedKey',
        'Detaylar:',
        ...errors,
      ];
    }

    return results;
  }

  @override
  Future<Map<String, dynamic>?> getQuotaInfo() async {
    return null;
  }
}
