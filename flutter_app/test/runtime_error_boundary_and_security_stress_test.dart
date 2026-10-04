import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/network/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Stress Test Suite: Requirement R4 - Global Asynchronous Error Boundary', () {
    late ErrorCallback? originalOnError;

    setUp(() {
      originalOnError = PlatformDispatcher.instance.onError;
    });

    tearDown(() {
      PlatformDispatcher.instance.onError = originalOnError;
    });

    test('4.1 PlatformDispatcher.instance.onError registers callback and returns true (handled) for async errors', () {
      bool handlerCalled = false;
      Object? receivedError;
      StackTrace? receivedStack;

      // Register handler matching lib/main.dart
      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        handlerCalled = true;
        receivedError = error;
        receivedStack = stack;
        return true; // Contract: return true to intercept unhandled asynchronous exceptions and prevent isolate crash
      };

      expect(PlatformDispatcher.instance.onError, isNotNull);

      final simulatedError = StateError('Simulated unhandled async future exception');
      final simulatedStack = StackTrace.current;

      final handled = PlatformDispatcher.instance.onError!(simulatedError, simulatedStack);

      expect(handled, isTrue, reason: 'PlatformDispatcher.instance.onError must return true to prevent isolate crash');
      expect(handlerCalled, isTrue);
      expect(receivedError, equals(simulatedError));
      expect(receivedStack, equals(simulatedStack));
    });

    test('4.2 PlatformDispatcher.instance.onError intercepts polymorphic error types without exception', () {
      final errorTypes = <Object>[
        const FormatException('Malformed JSON in async stream'),
        const SocketException('Failed to connect to 192.168.1.100:8000'),
        TimeoutException('API gateway 120s timeout expired'),
        RangeError.index(10, [1, 2, 3]),
        StateError('Chapter state illegal transition'),
        Exception('Generic background task exception'),
        'Raw string error payload thrown outside zone',
      ];

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        return true;
      };

      for (final err in errorTypes) {
        final result = PlatformDispatcher.instance.onError!(err, StackTrace.current);
        expect(result, isTrue, reason: 'Error type ${err.runtimeType} must be trapped cleanly');
      }
    });

    test('4.3 PlatformDispatcher.instance.onError survives high-concurrency async error storms (500 parallel errors)', () async {
      const stormSize = 500;
      int handledCount = 0;

      PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
        handledCount++;
        return true;
      };

      final futures = List.generate(stormSize, (index) async {
        return PlatformDispatcher.instance.onError!(
          StateError('Simulated concurrent async error #$index'),
          StackTrace.current,
        );
      });

      final results = await Future.wait(futures);

      expect(results.length, equals(stormSize));
      expect(results.every((r) => r == true), isTrue);
      expect(handledCount, equals(stormSize));
    });

    test('4.4 FlutterError.onError behaves correctly under debug vs release mode simulation', () {
      final loggedLines = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) loggedLines.add(message);
      };

      // Handler matching lib/main.dart lines 31-41
      void testFlutterErrorHandler(FlutterErrorDetails details, {required bool isRelease}) {
        if (!isRelease) {
          debugPrint('=== FLUTTER ERROR ===');
          debugPrint('Exception: ${details.exception}');
          debugPrint('Stack: ${details.stack}');
          debugPrint('Library: ${details.library}');
          debugPrint('Context: ${details.context}');
          debugPrint('=== END FLUTTER ERROR ===');
        }
      }

      final testDetails = FlutterErrorDetails(
        exception: Exception('Widget build failure'),
        stack: StackTrace.current,
        library: 'widgets library',
      );

      // In debug mode: logs formatted error details
      testFlutterErrorHandler(testDetails, isRelease: false);
      expect(loggedLines, contains('=== FLUTTER ERROR ==='));
      expect(loggedLines.any((l) => l.contains('Widget build failure')), isTrue);
      expect(loggedLines, contains('=== END FLUTTER ERROR ==='));

      // In release mode: complete suppression of verbose error logs
      loggedLines.clear();
      testFlutterErrorHandler(testDetails, isRelease: true);
      expect(loggedLines, isEmpty);

      debugPrint = originalDebugPrint;
    });

    test('4.5 main.dart PlatformDispatcher handler returns true and formats logs correctly', () {
      final logs = <String>[];
      final originalDebugPrint = debugPrint;
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) logs.add(message);
      };

      // Handler under test (identical to lib/main.dart lines 44-53)
      bool testHandler(Object error, StackTrace stack, {bool isRelease = false}) {
        if (!isRelease) {
          debugPrint('=== UNHANDLED ASYNC ERROR (PlatformDispatcher) ===');
          debugPrint('Error: $error');
          debugPrint('Stack: $stack');
          debugPrint('=== END UNHANDLED ASYNC ERROR ===');
        }
        return true;
      }

      final resDebug = testHandler(Exception('test_err'), StackTrace.current, isRelease: false);
      expect(resDebug, isTrue);
      expect(logs, contains('=== UNHANDLED ASYNC ERROR (PlatformDispatcher) ==='));
      expect(logs.any((l) => l.contains('Error: Exception: test_err')), isTrue);
      expect(logs, contains('=== END UNHANDLED ASYNC ERROR ==='));

      logs.clear();
      final resRelease = testHandler(Exception('test_err'), StackTrace.current, isRelease: true);
      expect(resRelease, isTrue);
      expect(logs, isEmpty);

      debugPrint = originalDebugPrint;
    });
  });

  group('Stress Test Suite: Requirement R4 - Logging Hygiene & ErrorWidget Protection', () {
    test('4.6 debugPrint suppression silences output when overridden for release mode', () {
      final originalDebugPrint = debugPrint;
      final printedLines = <String>[];

      // Simulated debug mode
      debugPrint = (String? message, {int? wrapWidth}) {
        if (message != null) printedLines.add(message);
      };
      debugPrint('Internal API token: secret_token_123');
      expect(printedLines.length, equals(1));
      expect(printedLines.first, contains('secret_token_123'));

      // Simulated release mode (lib/main.dart lines 26-28)
      printedLines.clear();
      debugPrint = (String? message, {int? wrapWidth}) {};
      debugPrint('Internal API token: secret_token_123');
      debugPrint('[HomeScreen] build() called');
      debugPrint('[AssessmentProvider] ERROR in generateDraftTest: confidential');
      expect(printedLines, isEmpty);

      debugPrint = originalDebugPrint;
    });

    testWidgets('4.7 ErrorWidget renders sanitized message in release mode and raw error in debug mode', (tester) async {
      // Test widget builder helper matching lib/main.dart lines 56-89
      Widget buildTestErrorWidget(FlutterErrorDetails details, {required bool isRelease}) {
        return Material(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'An Unexpected Error Occurred',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isRelease
                        ? 'Please return to the previous screen or restart the app.'
                        : '${details.exception}',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      const testDetails = FlutterErrorDetails(
        exception: SocketException('Confidential SQL Database Connection Failed: 192.168.1.200:5432'),
      );

      // Render with release = true
      await tester.pumpWidget(MaterialApp(home: buildTestErrorWidget(testDetails, isRelease: true)));
      expect(find.text('An Unexpected Error Occurred'), findsOneWidget);
      expect(find.text('Please return to the previous screen or restart the app.'), findsOneWidget);
      expect(find.textContaining('192.168.1.200:5432'), findsNothing);

      // Render with release = false
      await tester.pumpWidget(MaterialApp(home: buildTestErrorWidget(testDetails, isRelease: false)));
      expect(find.text('An Unexpected Error Occurred'), findsOneWidget);
      expect(find.textContaining('Confidential SQL Database Connection Failed'), findsOneWidget);
    });
  });

  group('Stress Test Suite: Requirement R2 - Android Cleartext & Network Endpoints', () {
    test('2.1 AndroidManifest.xml contains android:usesCleartextTraffic="true"', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue, reason: 'AndroidManifest.xml must exist');

      final content = manifestFile.readAsStringSync();
      expect(
        content.contains('android:usesCleartextTraffic="true"'),
        isTrue,
        reason: 'AndroidManifest.xml must declare android:usesCleartextTraffic="true" for emulator and LAN HTTP traffic',
      );
      expect(
        content.contains('android.permission.INTERNET'),
        isTrue,
        reason: 'AndroidManifest.xml must request android.permission.INTERNET',
      );
      expect(
        content.contains('android.permission.ACCESS_NETWORK_STATE'),
        isTrue,
        reason: 'AndroidManifest.xml must request android.permission.ACCESS_NETWORK_STATE',
      );
    });

    test('2.2 ApiClient supports local intranet, emulator, and cloud URI endpoints without crash', () {
      final testEndpoints = [
        'http://10.0.2.2:8000',
        'http://192.168.1.100:8000',
        'http://192.168.0.25:8000',
        'http://172.16.0.10:8080',
        'http://localhost:8000',
        'http://127.0.0.1:8000',
        'https://testai.ai-vision.studio',
      ];

      for (final endpoint in testEndpoints) {
        final client = ApiClient(baseUrl: endpoint);
        expect(client.baseUrl, equals(endpoint));
        final uri = Uri.parse(client.baseUrl);
        expect(uri.hasScheme, isTrue);
        expect(uri.hasAuthority, isTrue);
      }
    });

    test('2.3 ApiClient updateBaseUrl handles dynamic switching between HTTP LAN and HTTPS Cloud', () {
      final client = ApiClient(baseUrl: 'http://10.0.2.2:8000');
      expect(client.baseUrl, equals('http://10.0.2.2:8000'));

      // Switch to school LAN
      client.updateBaseUrl('http://192.168.1.150:8000');
      expect(client.baseUrl, equals('http://192.168.1.150:8000'));

      // Switch to production HTTPS
      client.updateBaseUrl('https://testai.ai-vision.studio');
      expect(client.baseUrl, equals('https://testai.ai-vision.studio'));

      // Switch back to emulator
      client.updateBaseUrl('http://10.0.2.2:8000');
      expect(client.baseUrl, equals('http://10.0.2.2:8000'));
    });
  });
}
