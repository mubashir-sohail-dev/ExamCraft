import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/core/network/api_client.dart';

void main() {
  group('ApiClient Unit Tests', () {
    late ApiClient apiClient;

    setUp(() {
      apiClient = ApiClient();
    });

    test('Should initialize with correct default base URL', () {
      expect(apiClient.baseUrl, equals(ApiClient.defaultBaseUrl));
    });

    test('Should update base URL dynamically', () {
      apiClient.updateBaseUrl('http://10.0.2.2:8000');
      expect(apiClient.baseUrl, equals('http://10.0.2.2:8000'));
    });

    test('ApiException toString should format message and status code correctly', () {
      final exception = ApiException(
        message: 'Resource not found',
        statusCode: 404,
      );
      expect(
        exception.toString(),
        contains('ApiException: Resource not found (StatusCode: 404)'),
      );
    });

    test('ValidationException hierarchy check', () {
      final valErr = ValidationException(
        message: 'Invalid subject requested',
        statusCode: 422,
        data: {'detail': 'Invalid subject'},
      );
      expect(valErr, isA<ApiException>());
      expect(valErr.statusCode, equals(422));
      expect(valErr.message, equals('Invalid subject requested'));
    });

    test('NetworkException hierarchy check', () {
      final netErr = NetworkException(
        message: 'Connection timeout',
        statusCode: null,
      );
      expect(netErr, isA<ApiException>());
      expect(netErr.statusCode, isNull);
    });

    test('ServerException hierarchy check', () {
      final serverErr = ServerException(
        message: 'Internal Server Error',
        statusCode: 500,
      );
      expect(serverErr, isA<ApiException>());
      expect(serverErr.statusCode, equals(500));
    });

    test('NotFoundException hierarchy check', () {
      final notFoundErr = NotFoundException(
        message: 'Chapter not found',
        statusCode: 404,
      );
      expect(notFoundErr, isA<ApiException>());
      expect(notFoundErr.statusCode, equals(404));
    });
  });
}
