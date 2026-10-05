import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_app/core/network/api_client.dart';
import 'package:flutter_app/data/models/settings_model.dart';
import 'package:flutter_app/data/repositories/settings_repository.dart';
import 'package:flutter_app/presentation/providers/settings_provider.dart';

/// In-memory mock HttpClientAdapter to intercept low-level Dio requests and inspect wire headers.
class WireCaptureHttpAdapter implements HttpClientAdapter {
  RequestOptions? lastRequestOptions;
  final List<RequestOptions> capturedRequests = [];
  ResponseBody Function(RequestOptions options)? responseHandler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequestOptions = options;
    capturedRequests.add(options);

    if (responseHandler != null) {
      return responseHandler!(options);
    }

    final responsePayload = jsonEncode({'status': 'ok', 'data': []});
    return ResponseBody.fromString(
      responsePayload,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stress Test Suite: Requirement R1 - Platform Base URL Resolution', () {
    test('1.1 Platform resolution matrix: isAndroid true, false, and null', () {
      // Explicit Android
      expect(
        ApiClient.resolveDefaultBaseUrl(isAndroid: true),
        equals('http://10.0.2.2:8000'),
      );

      // Explicit non-Android (Desktop / iOS / Web)
      expect(
        ApiClient.resolveDefaultBaseUrl(isAndroid: false),
        equals('http://localhost:8000'),
      );

      // Default (null flag) resolves against current host Platform.isAndroid
      final expectedDefault = Platform.isAndroid
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000';
      expect(ApiClient.resolveDefaultBaseUrl(), equals(expectedDefault));
      expect(ApiClient.defaultBaseUrl, equals(expectedDefault));
    });

    test('1.2 ApiClient constructor resolves default URL or respects explicit override', () {
      final defaultClient = ApiClient();
      final expectedDefault = Platform.isAndroid
          ? 'http://10.0.2.2:8000'
          : 'http://localhost:8000';
      expect(defaultClient.baseUrl, equals(expectedDefault));

      final customClient = ApiClient(baseUrl: 'https://custom-cluster.internal:8443');
      expect(customClient.baseUrl, equals('https://custom-cluster.internal:8443'));
    });

    test('1.3 Dynamic base URL mutation updates in-memory and underlying Dio configuration', () {
      final client = ApiClient();
      expect(client.baseUrl, isNotEmpty);

      client.updateBaseUrl('http://192.168.1.100:8000');
      expect(client.baseUrl, equals('http://192.168.1.100:8000'));
    });
  });

  group('Stress Test Suite: Requirement R1 - Route Inspection & Edge Case Paths', () {
    late ApiClient client;

    setUp(() {
      client = ApiClient(
        clientApiKey: 'test-fixture-client-key',
        adminApiKey: 'test-fixture-admin-key',
      );
    });

    test('2.1 Route classification: standard client endpoints', () {
      final clientPaths = [
        '/api/subjects',
        '/api/subjects/Chemistry/chapters',
        '/api/subjects/Mathematics/chapters/Matrices/metadata',
        '/api/tests/draft',
        '/api/tests/123/status',
        '/api/tests/history',
        '/api/export-pdf',
      ];

      for (final path in clientPaths) {
        expect(
          client.getApiKeyForPath(path),
          equals('test-fixture-client-key'),
          reason: 'Path "$path" must receive client API key',
        );
        expect(
          client.getHeadersForPath(path)['X-API-Key'],
          equals('test-fixture-client-key'),
        );
      }
    });

    test('2.2 Route classification: admin and textbook upload endpoints', () {
      final adminPaths = [
        '/api/admin',
        '/api/admin/',
        '/api/admin/collections/upload',
        '/api/admin/indexing/status',
        '/api/admin/system-stats',
        '/api/upload-textbook',
        '/upload-textbook',
        '/api/admin/reset',
      ];

      for (final path in adminPaths) {
        expect(
          client.getApiKeyForPath(path),
          equals('test-fixture-admin-key'),
          reason: 'Path "$path" must receive admin API key',
        );
        expect(
          client.getHeadersForPath(path)['X-API-Key'],
          equals('test-fixture-admin-key'),
        );
      }
    });

    test('2.3 Edge case paths: sub-paths, trailing slashes, and substring matching', () {
      // Admin route with trailing slash
      expect(client.getApiKeyForPath('/api/admin/'), equals('test-fixture-admin-key'));

      // Nested admin subpath
      expect(client.getApiKeyForPath('/api/admin/collections/upload'), equals('test-fixture-admin-key'));

      // Path without leading slash: 'api/admin'
      // Note: _isAdminRoute checks contains('/api/admin') so 'api/admin' lacks leading slash
      final lacksLeadingSlash = client.getApiKeyForPath('api/admin/test');
      expect(
        lacksLeadingSlash,
        equals('test-fixture-client-key'),
        reason: 'Path without leading slash does not match "/api/admin" - empirical verification of substring pattern',
      );

      // Substring match: route containing "upload-textbook"
      expect(
        client.getApiKeyForPath('/api/tests/upload-textbook-summary'),
        equals('test-fixture-admin-key'),
        reason: 'Any path containing "upload-textbook" triggers admin key',
      );

      // Empty string path
      expect(client.getApiKeyForPath(''), equals('test-fixture-client-key'));
    });
  });

  group('Stress Test Suite: Requirement R1 - Interceptor Wire Execution & Dynamic Mutation', () {
    test('3.1 Custom Dio instance receives interceptor and executes across wire requests', () async {
      final mockAdapter = WireCaptureHttpAdapter();
      final customDio = Dio(
        BaseOptions(
          baseUrl: 'http://custom-dio.local:8000',
          headers: {'X-Custom-Client-Id': 'Flutter-Device-99'},
        ),
      );
      customDio.httpClientAdapter = mockAdapter;

      final client = ApiClient(
        customDio: customDio,
        clientApiKey: 'test-fixture-client-key',
        adminApiKey: 'test-fixture-admin-key',
      );

      // Verify interceptor is attached to customDio
      expect(customDio.interceptors.isNotEmpty, isTrue);

      // Execute GET request to client route
      final response = await client.get('/api/subjects');
      expect(response, isNotNull);

      // Verify low-level wire headers captured by adapter
      expect(mockAdapter.lastRequestOptions, isNotNull);
      final headers = mockAdapter.lastRequestOptions!.headers;
      expect(headers['X-API-Key'], equals('test-fixture-client-key'));
      expect(headers['X-Custom-Client-Id'], equals('Flutter-Device-99'));
    });

    test('3.2 Sequential requests with dynamic mutation of clientApiKey and adminApiKey', () async {
      final mockAdapter = WireCaptureHttpAdapter();
      final customDio = Dio(BaseOptions(baseUrl: 'http://test-wire:8000'));
      customDio.httpClientAdapter = mockAdapter;

      final client = ApiClient(
        customDio: customDio,
        clientApiKey: 'fixture-client-token-111',
        adminApiKey: 'fixture-admin-token-222',
      );

      // Request 1: Client route with fixture key
      await client.get('/api/subjects');
      expect(
        mockAdapter.capturedRequests.last.headers['X-API-Key'],
        equals('fixture-client-token-111'),
      );

      // Mutate clientApiKey
      client.updateClientApiKey('custom-teacher-auth-token-111');
      expect(client.clientApiKey, equals('custom-teacher-auth-token-111'));

      // Request 2: Client route with mutated key
      await client.get('/api/subjects/Mathematics/chapters');
      expect(
        mockAdapter.capturedRequests.last.headers['X-API-Key'],
        equals('custom-teacher-auth-token-111'),
      );

      // Request 3: Admin route with fixture admin key
      await client.get('/api/admin/indexing/status');
      expect(
        mockAdapter.capturedRequests.last.headers['X-API-Key'],
        equals('fixture-admin-token-222'),
      );

      // Mutate adminApiKey
      client.updateAdminApiKey('super-admin-root-token-999');
      expect(client.adminApiKey, equals('super-admin-root-token-999'));

      // Request 4: Admin route with mutated admin key
      await client.get('/api/admin/system-stats');
      expect(
        mockAdapter.capturedRequests.last.headers['X-API-Key'],
        equals('super-admin-root-token-999'),
      );

      // Request 5: Client route still uses mutated client key (isolation check)
      await client.get('/api/tests/draft');
      expect(
        mockAdapter.capturedRequests.last.headers['X-API-Key'],
        equals('custom-teacher-auth-token-111'),
      );

      // Total sequential wire requests captured
      expect(mockAdapter.capturedRequests.length, equals(5));
    });

    test('3.3 Updating baseUrl dynamically updates wire destination on subsequent requests', () async {
      final mockAdapter = WireCaptureHttpAdapter();
      final customDio = Dio(BaseOptions(baseUrl: 'http://initial-host:8000'));
      customDio.httpClientAdapter = mockAdapter;

      final client = ApiClient(customDio: customDio);

      await client.get('/api/subjects');
      expect(mockAdapter.lastRequestOptions!.baseUrl, equals('http://initial-host:8000'));

      client.updateBaseUrl('http://switched-host:9090');
      await client.get('/api/subjects');
      expect(mockAdapter.lastRequestOptions!.baseUrl, equals('http://switched-host:9090'));
      expect(client.baseUrl, equals('http://switched-host:9090'));
    });
  });

  group('Stress Test Suite: Requirement R5 - SettingsModel Serialization & Deserialization', () {
    test('4.1 Deserialization with empty map {} uses all defaults', () {
      final model = SettingsModel.fromJson({});
      expect(model.baseUrl, equals('https://testai.ai-vision.studio'));
      expect(model.clientApiKey, equals(''));
      expect(model.adminApiKey, equals(''));
      expect(model.defaultMcqCount, equals(5));
      expect(model.defaultShortCount, equals(3));
      expect(model.defaultLongCount, equals(1));
      expect(model.includeAnswerKey, isTrue);
      expect(model.enableTelemetry, isTrue);
      expect(model.enableDebugLogs, isTrue);
      expect(model.isDarkMode, isFalse);
      expect(model.maxContextChars, equals(12000));
    });

    test('4.2 Deserialization with null values falls back safely to defaults', () {
      final model = SettingsModel.fromJson({
        'base_url': null,
        'client_api_key': null,
        'admin_api_key': null,
        'default_mcq_count': null,
        'default_short_count': null,
        'default_long_count': null,
        'include_answer_key': null,
        'enable_telemetry': null,
        'enable_debug_logs': null,
        'is_dark_mode': null,
        'max_context_chars': null,
      });

      expect(model.baseUrl, equals('https://testai.ai-vision.studio'));
      expect(model.clientApiKey, equals(''));
      expect(model.adminApiKey, equals(''));
      expect(model.defaultMcqCount, equals(5));
      expect(model.defaultShortCount, equals(3));
      expect(model.defaultLongCount, equals(1));
      expect(model.includeAnswerKey, isTrue);
      expect(model.enableTelemetry, isTrue);
      expect(model.enableDebugLogs, isTrue);
      expect(model.isDarkMode, isFalse);
      expect(model.maxContextChars, equals(12000));
    });

    test('4.3 Deserialization with custom values and extraneous unexpected keys', () {
      final model = SettingsModel.fromJson({
        'base_url': 'http://192.168.0.50:8000',
        'client_api_key': 'school-key-abc',
        'default_mcq_count': 10,
        'default_short_count': 6,
        'default_long_count': 2,
        'include_answer_key': false,
        'enable_telemetry': false,
        'enable_debug_logs': false,
        'is_dark_mode': true,
        'max_context_chars': 15000,
        'unknown_field_1': 'ignored_value',
        'nested_extra': {'foo': 42},
      });

      expect(model.baseUrl, equals('http://192.168.0.50:8000'));
      expect(model.clientApiKey, equals('school-key-abc'));
      expect(model.defaultMcqCount, equals(10));
      expect(model.defaultShortCount, equals(6));
      expect(model.defaultLongCount, equals(2));
      expect(model.includeAnswerKey, isFalse);
      expect(model.enableTelemetry, isFalse);
      expect(model.enableDebugLogs, isFalse);
      expect(model.isDarkMode, isTrue);
      expect(model.maxContextChars, equals(15000));
    });

    test('4.4 Serialization toJson() produces correct JSON mapping and roundtrips', () {
      const original = SettingsModel(
        baseUrl: 'http://10.0.2.2:8000',
        clientApiKey: 'test-roundtrip-key',
        adminApiKey: 'test-admin-roundtrip-key',
        defaultMcqCount: 8,
        defaultShortCount: 4,
        defaultLongCount: 3,
        includeAnswerKey: false,
        enableTelemetry: false,
        enableDebugLogs: true,
        isDarkMode: true,
        maxContextChars: 25000,
      );

      final json = original.toJson();
      expect(json['base_url'], equals('http://10.0.2.2:8000'));
      expect(json['client_api_key'], equals('test-roundtrip-key'));
      expect(json['admin_api_key'], equals('test-admin-roundtrip-key'));
      expect(json['default_mcq_count'], equals(8));
      expect(json['default_short_count'], equals(4));
      expect(json['default_long_count'], equals(3));
      expect(json['include_answer_key'], equals(false));
      expect(json['enable_telemetry'], equals(false));
      expect(json['enable_debug_logs'], equals(true));
      expect(json['is_dark_mode'], equals(true));
      expect(json['max_context_chars'], equals(25000));

      final roundtripped = SettingsModel.fromJson(json);
      expect(roundtripped.baseUrl, equals(original.baseUrl));
      expect(roundtripped.clientApiKey, equals(original.clientApiKey));
      expect(roundtripped.adminApiKey, equals(original.adminApiKey));
      expect(roundtripped.defaultMcqCount, equals(original.defaultMcqCount));
      expect(roundtripped.defaultShortCount, equals(original.defaultShortCount));
      expect(roundtripped.defaultLongCount, equals(original.defaultLongCount));
      expect(roundtripped.includeAnswerKey, equals(original.includeAnswerKey));
      expect(roundtripped.enableTelemetry, equals(original.enableTelemetry));
      expect(roundtripped.enableDebugLogs, equals(original.enableDebugLogs));
      expect(roundtripped.isDarkMode, equals(original.isDarkMode));
      expect(roundtripped.maxContextChars, equals(original.maxContextChars));
    });

    test('4.5 copyWith updates specified fields and preserves unpassed fields', () {
      const model = SettingsModel();
      final updated = model.copyWith(
        clientApiKey: 'brand-new-key',
        adminApiKey: 'brand-new-admin-key',
        isDarkMode: true,
      );

      expect(updated.clientApiKey, equals('brand-new-key'));
      expect(updated.adminApiKey, equals('brand-new-admin-key'));
      expect(updated.isDarkMode, isTrue);
      // Preserved fields
      expect(updated.baseUrl, equals(model.baseUrl));
      expect(updated.defaultMcqCount, equals(model.defaultMcqCount));
      expect(updated.maxContextChars, equals(model.maxContextChars));
    });
  });

  group('Stress Test Suite: Reviewer 1 Finding 1 Empirical Investigation', () {
    test('5.1 Verify startup race: SettingsProvider overwrites ApiClient.baseUrl with cloud URL', () async {
      // Simulate fresh install with empty SharedPreferences
      SharedPreferences.setMockInitialValues({});
      final settingsRepo = SettingsRepository();

      // On Android emulator, ApiClient initializes to 10.0.2.2:8000
      final androidClient = ApiClient(baseUrl: 'http://10.0.2.2:8000');
      expect(androidClient.baseUrl, equals('http://10.0.2.2:8000'));

      // Initialize SettingsProvider with androidClient
      final provider = SettingsProvider(
        settingsRepository: settingsRepo,
        apiClient: androidClient,
      );

      // Await settings load to settle
      await Future.delayed(const Duration(milliseconds: 50));

      // EMPIRICAL OBSERVATION OF FINDING 1:
      // When SharedPreferences is empty, SettingsRepository returns SettingsModel()
      // whose default baseUrl is 'https://testai.ai-vision.studio'.
      // SettingsProvider.loadSettings() then executes:
      // apiClient!.updateBaseUrl(_settings.baseUrl);
      // which OVERWRITES ApiClient's platform base URL!
      expect(
        androidClient.baseUrl,
        equals('https://testai.ai-vision.studio'),
        reason: 'Empirically confirms Reviewer 1 Finding 1: SettingsProvider overwrites ApiClient platform URL with hardcoded cloud default',
      );
      expect(
        provider.baseUrl,
        equals('https://testai.ai-vision.studio'),
      );
    });

    test('5.2 When user manually saves URL preset, persistence survives subsequent provider reload', () async {
      SharedPreferences.setMockInitialValues({});
      final settingsRepo = SettingsRepository();
      final client = ApiClient();

      final provider1 = SettingsProvider(
        settingsRepository: settingsRepo,
        apiClient: client,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // User selects Android Emulator preset and saves
      await provider1.updateBaseUrl('http://10.0.2.2:8000');
      await provider1.updateClientApiKey('custom-persisted-teacher-key');

      expect(client.baseUrl, equals('http://10.0.2.2:8000'));
      expect(client.clientApiKey, equals('custom-persisted-teacher-key'));

      // Now simulate app restart: new ApiClient and new SettingsProvider reading persisted storage
      final rebootClient = ApiClient();
      final provider2 = SettingsProvider(
        settingsRepository: settingsRepo,
        apiClient: rebootClient,
      );
      await Future.delayed(const Duration(milliseconds: 50));

      // Persisted values must correctly overwrite rebootClient defaults and initialize provider2
      expect(rebootClient.baseUrl, equals('http://10.0.2.2:8000'));
      expect(rebootClient.clientApiKey, equals('custom-persisted-teacher-key'));
      expect(provider2.baseUrl, equals('http://10.0.2.2:8000'));
      expect(provider2.clientApiKey, equals('custom-persisted-teacher-key'));
    });
  });
}
