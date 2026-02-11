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

  /// Ücretsiz tier'da çalışan modeller (düşük kota tüketimi)
  static const List<ModelInfo> _models = [
    ModelInfo(
      id: 'gemini-2.0-flash-lite',
      displayName: 'Gemini 2.0 Flash Lite',
      description: 'En hafif model - 1500 istek/gün',
      isFreeTier: true,
      quotaLimit: 1500,
    ),
    ModelInfo(
      id: 'gemini-2.0-flash',
      displayName: 'Gemini 2.0 Flash',
      description: 'Hızlı ve dengeli - 1000 istek/gün',
      isFreeTier: true,
      quotaLimit: 1000,
    ),
    ModelInfo(
      id: 'gemini-1.5-flash',
      displayName: 'Gemini 1.5 Flash',
      description: 'Stabil ve güvenilir - 1000 istek/gün',
      isFreeTier: true,
      quotaLimit: 1000,
    ),
    ModelInfo(
      id: 'gemini-2.5-flash',
      displayName: 'Gemini 2.5 Flash',
      description: 'En yeni model - 500 istek/gün',
      isFreeTier: true,
      quotaLimit: 500,
    ),
    ModelInfo(
      id: 'gemini-2.5-pro',
      displayName: 'Gemini 2.5 Pro',
      description: 'En kaliteli - 100 istek/gün',
      isFreeTier: true,
      quotaLimit: 100,
    ),
  ];

  /// Kota dostu sıralama (en yüksek kotadan düşüğe)
  List<ModelInfo> get _quotaFriendlyModels {
    return List.from(_models)
      ..sort((a, b) => (b.quotaLimit ?? 0).compareTo(a.quotaLimit ?? 0));
  }

  String get _storageKey => StorageKeys.aiModel;

  @override
  String get selectedModel {
    return _prefs.getString(_storageKey) ?? _quotaFriendlyModels.first.id;
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

  /// Fallback mekanizması ile model oluşturma
  Future<({GenerativeModel? model, String? error, String modelId})>
  _getModelWithFallback() async {
    // Önce seçili modeli dene
    final primaryModel = _getModel();
    if (primaryModel == null) {
      return (model: null, error: 'API Key not configured', modelId: '');
    }

    try {
      // Test et
      await primaryModel.generateContent([
        Content.text('Test'),
      ], generationConfig: GenerationConfig(maxOutputTokens: 1));
      return (model: primaryModel, error: null, modelId: selectedModel);
    } catch (e) {
      debugPrint('Primary model failed: $e');

      // Kota hatası mı?
      if (e.toString().contains('429') || e.toString().contains('quota')) {
        // Sıradaki modele geç
        final currentIndex = _quotaFriendlyModels.indexWhere(
          (m) => m.id == selectedModel,
        );

        for (int i = 0; i < _quotaFriendlyModels.length; i++) {
          if (i == currentIndex) continue; // Aynı modeli tekrar deneme

          final fallbackModel = _quotaFriendlyModels[i];
          try {
            final model = _getModel(overrideModel: fallbackModel.id);
            if (model != null) {
              await model.generateContent([
                Content.text('Test'),
              ], generationConfig: GenerationConfig(maxOutputTokens: 1));

              // Otomatik geçiş yap
              await setModel(fallbackModel.id);
              debugPrint(
                'Auto-switched to fallback model: ${fallbackModel.id}',
              );

              return (model: model, error: null, modelId: fallbackModel.id);
            }
          } catch (fallbackError) {
            debugPrint(
              'Fallback model ${fallbackModel.id} failed: $fallbackError',
            );
            continue;
          }
        }

        return (
          model: null,
          error:
              'Tüm modellerin kotası dolmuş. Lütfen daha sonra tekrar deneyin.',
          modelId: '',
        );
      }

      return (model: null, error: e.toString(), modelId: '');
    }
  }

  @override
  Future<String> summarize(String text) async {
    final modelResult = await _getModelWithFallback();

    if (modelResult.model == null) {
      return "Hata: ${modelResult.error ?? 'Model oluşturulamadı'}";
    }

    final prompt = [
      Content.text(
        "$_promptBase\n\nPlease provide a concise, elegant summary (max 2 sentences) of the following journal entry:\n\n$text",
      ),
    ];

    try {
      final response = await modelResult.model!.generateContent(prompt);
      return response.text ?? "Could not generate summary.";
    } catch (e) {
      debugPrint('AI Service Error (Summarize): $e');
      return _handleError(e);
    }
  }

  @override
  Future<String> continueWriting(String text, {String? context}) async {
    final modelResult = await _getModelWithFallback();

    if (modelResult.model == null) {
      return "[Hata: ${modelResult.error ?? 'AI şuanda kullanılamıyor'}]";
    }

    final contextPart =
        context != null ? "Context about the day: $context\n" : "";
    final prompt = [
      Content.text(
        "$_promptBase\n${contextPart}Existing text: $text\n\nPlease continue the writing naturally, maintaining the user's style. Provide only the continuation text, max 3-4 sentences.",
      ),
    ];

    try {
      final response = await modelResult.model!.generateContent(prompt);
      return response.text ?? "";
    } catch (e) {
      debugPrint('AI Service Error (Continue): $e');
      return "[Hata: ${_handleError(e)}]";
    }
  }

  @override
  Future<List<String>> generateTags(String text) async {
    final modelResult = await _getModelWithFallback();

    if (modelResult.model == null) {
      return [];
    }

    final prompt = [
      Content.text(
        "$_promptBase\nText: $text\n\nSuggest 3-5 relevant hashtags/tags for this entry. Provide only the tags separated by commas, no introductory text.",
      ),
    ];

    try {
      final response = await modelResult.model!.generateContent(prompt);
      final tagsRaw = response.text ?? "";
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

    if (errorStr.contains('403') ||
        errorStr.contains('API key') ||
        errorStr.contains('permission')) {
      return 'Geçersiz API Anahtarı. Ayarlar > AI Asistan bölümünü kontrol edin.';
    }
    if (errorStr.contains('404') || errorStr.contains('not found')) {
      return 'AI modeli mevcut değil. Lütfen daha sonra tekrar deneyin.';
    }
    if (errorStr.contains('429') ||
        errorStr.contains('quota') ||
        errorStr.contains('rate limit')) {
      return 'API kotası doldu. Otomatik olarak alternatif modele geçildi veya lütfen daha sonra tekrar deneyin.';
    }
    if (errorStr.contains('timeout') || errorStr.contains('deadline')) {
      return 'İstek zaman aşımına uğradı. İnternet bağlantınızı kontrol edin.';
    }
    return 'AI hatası: ${errorStr.substring(0, errorStr.length > 100 ? 100 : errorStr.length)}';
  }

  @override
  Future<List<String>> listAvailableModels() async {
    final apiKey = _prefs.getString('ai_api_key');
    if (apiKey == null || apiKey.isEmpty) return ['API Key not configured'];

    final available = <String>[];
    final errors = <String>[];

    // Kota dostu sıralamayla test et
    for (final modelInfo in _quotaFriendlyModels) {
      try {
        final model = GenerativeModel(model: modelInfo.id, apiKey: apiKey);
        await model.generateContent([
          Content.text('Test'),
        ], generationConfig: GenerationConfig(maxOutputTokens: 1));
        available.add(
          '${modelInfo.displayName} ✓ (${modelInfo.quotaLimit}/gün)',
        );
      } catch (e) {
        String errorMsg = e.toString();
        if (errorMsg.contains('404') || errorMsg.contains('not found')) {
          errorMsg = 'Model bulunamadı';
        } else if (errorMsg.contains('403')) {
          errorMsg = 'Erişim yok';
        } else if (errorMsg.contains('429')) {
          errorMsg = 'Kota doldu';
        }
        errors.add('${modelInfo.displayName}: $errorMsg');
      }
    }

    if (available.isEmpty) {
      return ['Çalışan model bulunamadı.', ...errors];
    }
    return [...available, ...errors];
  }

  @override
  Future<Map<String, dynamic>?> getQuotaInfo() async {
    // Google Gemini API direkt kota bilgisi vermez
    // Bu yüzden istek sayısını kendimiz takip edebiliriz
    // Şimdilik null dönüyoruz, ileride istek sayacı ekleyebiliriz

    final lastRequestKey = 'ai_last_request_time';
    final requestCountKey = 'ai_daily_request_count';

    final lastRequest = _prefs.getString(lastRequestKey);
    final now = DateTime.now();

    if (lastRequest != null) {
      final lastDate = DateTime.tryParse(lastRequest);
      if (lastDate != null) {
        // Gün değişmiş mi kontrol et
        if (lastDate.day != now.day ||
            lastDate.month != now.month ||
            lastDate.year != now.year) {
          // Yeni gün, sayacı sıfırla
          await _prefs.setInt(requestCountKey, 0);
          await _prefs.setString(lastRequestKey, now.toIso8601String());
          return {
            'remaining': selectedModelInfo.quotaLimit,
            'used': 0,
            'limit': selectedModelInfo.quotaLimit,
            'resetTime':
                DateTime(now.year, now.month, now.day + 1).toIso8601String(),
          };
        }
      }
    }

    final usedCount = _prefs.getInt(requestCountKey) ?? 0;
    final limit = selectedModelInfo.quotaLimit ?? 1000;

    return {
      'remaining': limit - usedCount,
      'used': usedCount,
      'limit': limit,
      'resetTime': DateTime(now.year, now.month, now.day + 1).toIso8601String(),
    };
  }

  ModelInfo get selectedModelInfo {
    return _models.firstWhere(
      (m) => m.id == selectedModel,
      orElse: () => _quotaFriendlyModels.first,
    );
  }

  /// Her AI isteğinde çağrılması gereken metod
  Future<void> _incrementRequestCount() async {
    final requestCountKey = 'ai_daily_request_count';
    final lastRequestKey = 'ai_last_request_time';
    final now = DateTime.now();

    final currentCount = _prefs.getInt(requestCountKey) ?? 0;
    await _prefs.setInt(requestCountKey, currentCount + 1);
    await _prefs.setString(lastRequestKey, now.toIso8601String());
  }
}
