import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:rojnivis/core/services/ai_service.dart';

class MockFirebaseRemoteConfig extends Mock implements FirebaseRemoteConfig {}
class MockHttpClient extends Mock implements http.Client {}

// Register fallback values
class FakeUri extends Fake implements Uri {}
class FakeHttpRequest extends Fake implements http.BaseRequest {}
class FakeRemoteConfigSettings extends Fake implements RemoteConfigSettings {}

void main() {
  late MockFirebaseRemoteConfig mockRemoteConfig;
  late MockHttpClient mockHttpClient;
  late SharedPreferences prefs;
  late GeminiAiService aiService;

  setUpAll(() {
    registerFallbackValue(FakeUri());
    registerFallbackValue(FakeHttpRequest());
    registerFallbackValue(FakeRemoteConfigSettings());
  });

  setUp(() async {
    mockRemoteConfig = MockFirebaseRemoteConfig();
    mockHttpClient = MockHttpClient();
    
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();

    // Default RC behavior
    when(() => mockRemoteConfig.getString('gemini_api_key')).thenReturn('dummy_key');
    when(() => mockRemoteConfig.fetchAndActivate()).thenAnswer((_) async => true);
    when(() => mockRemoteConfig.setConfigSettings(any())).thenAnswer((_) async => {});
    when(() => mockRemoteConfig.setDefaults(any())).thenAnswer((_) async => {});

    aiService = GeminiAiService(
      prefs,
      remoteConfig: mockRemoteConfig,
      httpClient: mockHttpClient,
    );
  });

  group('GeminiAiService Initialization', () {
    test('isConfigured is true if API key exists', () {
      expect(aiService.isConfigured, isTrue);
    });

    test('isConfigured is false if API key is empty', () {
      when(() => mockRemoteConfig.getString('gemini_api_key')).thenReturn('');
      expect(aiService.isConfigured, isFalse);
    });
  });

  group('Content Generation', () {
    final successResponse = http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'Summary text'}
              ],
              'role': 'model'
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    final tagsResponse = http.Response(
      jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'happy, productive, morning'}
              ],
              'role': 'model'
            }
          }
        ]
      }),
      200,
      headers: {'content-type': 'application/json'},
    );

    test('summarize returns summary on success', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => successResponse);

      final result = await aiService.summarize('Some long journal entry');
      expect(result, 'Summary text');
    });

    test('summarize handles auto-healing on 429 quota exhaustion', () async {
      final errorResponse = http.Response(
        jsonEncode({
          'error': {
            'message': 'Quota exceeded',
            'status': 'RESOURCE_EXHAUSTED',
            'code': 429
          }
        }),
        429,
        headers: {'content-type': 'application/json'},
      );

      // Primary fails with 429, then fallback succeeds
      int callCount = 0;
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) {
          return errorResponse;
        }
        return successResponse;
      });

      final result = await aiService.summarize('Some long journal entry');
      
      // Verify that it ultimately succeeded using the fallback model
      expect(result, 'Summary text');
      expect(callCount, greaterThan(1));
    });

    test('generateTags returns tags list', () async {
      when(() => mockHttpClient.post(
            any(),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => tagsResponse);

      final result = await aiService.generateTags('A nice morning');
      expect(result, equals(['happy', 'productive', 'morning']));
    });
  });
}
