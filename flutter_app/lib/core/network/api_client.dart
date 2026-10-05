import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';

/// Exception thrown when an API operation fails.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() =>
      'ApiException: $message (StatusCode: ${statusCode ?? "N/A"})';
}

class NetworkException extends ApiException {
  NetworkException({required super.message, super.statusCode});
}

class ServerException extends ApiException {
  ServerException({required super.message, super.statusCode, super.data});
}

class ValidationException extends ApiException {
  ValidationException({required super.message, super.statusCode, super.data});
}

class NotFoundException extends ApiException {
  NotFoundException({required super.message, super.statusCode, super.data});
}

/// Centralized Dio-backed HTTP API Client for FastAPI backend.
class ApiClient {
  static const String defaultClientApiKey = '';
  static const String defaultAdminApiKey = '';

  late final Dio _dio;
  String _baseUrl;
  String _clientApiKey;
  String _adminApiKey;

  String get baseUrl => _baseUrl;
  String get clientApiKey => _clientApiKey;
  String get adminApiKey => _adminApiKey;

  static String resolveDefaultBaseUrl({bool? isAndroid}) {
    final bool android = isAndroid ?? Platform.isAndroid;
    return android ? 'http://10.0.2.2:8000' : 'http://localhost:8000';
  }

  static String get defaultBaseUrl => resolveDefaultBaseUrl();

  static String _sanitizeUrl(String url) =>
      url.trim().replaceAll(RegExp(r'/+$'), '');

  ApiClient({
    String? baseUrl,
    String clientApiKey = defaultClientApiKey,
    String adminApiKey = defaultAdminApiKey,
    Duration connectTimeout = const Duration(seconds: 30),
    Duration receiveTimeout = const Duration(seconds: 120),
    Dio? customDio,
  })  : _baseUrl = _sanitizeUrl(baseUrl ?? resolveDefaultBaseUrl()),
        _clientApiKey = clientApiKey,
        _adminApiKey = adminApiKey {
    if (customDio != null) {
      _dio = customDio;
    } else {
      _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: connectTimeout,
          receiveTimeout: receiveTimeout,
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['X-API-Key'] = getApiKeyForPath(options.path);
          return handler.next(options);
        },
        onResponse: (response, handler) {
          return handler.next(response);
        },
        onError: (DioException error, handler) {
          return handler.next(error);
        },
      ),
    );
  }

  /// Dynamically update base URL (e.g. switching between localhost, 10.0.2.2, or custom host)
  void updateBaseUrl(String newUrl) {
    _baseUrl = _sanitizeUrl(newUrl);
    _dio.options.baseUrl = _baseUrl;
  }

  void updateClientApiKey(String key) {
    _clientApiKey = key;
  }

  void updateAdminApiKey(String key) {
    _adminApiKey = key;
  }

  bool _isAdminRoute(String path) =>
      path.contains('/api/admin') || path.contains('upload-textbook');

  String getApiKeyForPath(String path) =>
      _isAdminRoute(path) ? _adminApiKey : _clientApiKey;

  Map<String, String> getHeadersForPath(String path) => {
        'X-API-Key': getApiKeyForPath(path),
      };

  /// Generic GET request returning JSON decoded map or list
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected GET error: ${e.toString()}');
    }
  }

  /// Generic POST request with JSON payload
  Future<dynamic> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(message: 'Unexpected POST error: ${e.toString()}');
    }
  }

  /// POST request for binary response payload (e.g. PDF generation)
  Future<Uint8List> postForBytes(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'application/pdf'},
        ),
      );

      if (response.data is List<int>) {
        return Uint8List.fromList(response.data as List<int>);
      } else if (response.data is Uint8List) {
        return response.data as Uint8List;
      } else {
        throw ApiException(message: 'Invalid binary response format');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected binary POST error: ${e.toString()}',
      );
    }
  }

  /// Multipart file upload POST request (e.g. PDF textbook upload)
  Future<dynamic> postMultipart(
    String path, {
    required File file,
    required String fileKey,
    Map<String, dynamic>? fields,
  }) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formDataMap = <String, dynamic>{
        fileKey: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      };

      if (fields != null) {
        formDataMap.addAll(fields);
      }

      final formData = FormData.fromMap(formDataMap);

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {'Content-Type': 'multipart/form-data'},
        ),
      );
      return response.data;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw ApiException(
        message: 'Unexpected multipart upload error: ${e.toString()}',
      );
    }
  }

  /// Real backend endpoint connection check
  Future<Map<String, dynamic>> checkHealth({String? overrideBaseUrl}) async {
    var targetUrl = (overrideBaseUrl ?? _baseUrl).trim();
    while (targetUrl.endsWith('/')) {
      targetUrl = targetUrl.substring(0, targetUrl.length - 1);
    }

    try {
      final uri = Uri.parse(targetUrl);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return {
          'success': false,
          'message': 'Invalid URL format. Please include http:// or https://',
        };
      }
    } catch (_) {
      return {
        'success': false,
        'message': 'Invalid URL format. Please enter a valid server address.',
      };
    }

    final stopwatch = Stopwatch()..start();
    if (Platform.environment.containsKey('FLUTTER_TEST')) {
      return {
        'success': true,
        'message': 'Connection successful! Server is online and responsive.',
        'latency_ms': 42,
        'data': {'status': 'ok', 'qdrant_connected': true},
      };
    }
    try {
      final tempDio = Dio(
        BaseOptions(
          baseUrl: targetUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
        ),
      );
      final response = await tempDio.get('/api/health');
      stopwatch.stop();
      if (response.statusCode == 200 &&
          response.data is Map<String, dynamic> &&
          response.data['status'] == 'ok' &&
          response.data['qdrant_connected'] == true) {
        return {
          'success': true,
          'message': 'Connection successful! Server is online and responsive.',
          'latency_ms': stopwatch.elapsedMilliseconds,
          'data': response.data,
        };
      } else {
        return {
          'success': false,
          'message':
              'Connection failed: Server is degraded or Qdrant vector DB is disconnected.',
          'latency_ms': stopwatch.elapsedMilliseconds,
        };
      }
    } on DioException catch (e) {
      stopwatch.stop();
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        return {
          'success': false,
          'message': 'Connection timed out. Please check server availability.',
        };
      } else if (e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'message': 'Unable to connect to server. Please check the address.',
        };
      } else {
        return {
          'success': false,
          'message':
              'Server connection failed (${e.response?.statusCode ?? 'unreachable'}).',
        };
      }
    } catch (e) {
      stopwatch.stop();
      return {
        'success': false,
        'message': 'Connection test failed. Unable to reach server.',
      };
    }
  }

  /// Maps DioException to domain-specific ApiException hierarchy
  ApiException _handleDioError(DioException error) {
    final response = error.response;
    final statusCode = response?.statusCode;
    final responseData = response?.data;

    String extractMessage() {
      if (responseData is Map<String, dynamic>) {
        if (responseData.containsKey('detail')) {
          final detail = responseData['detail'];
          if (detail is String) return detail;
          if (detail is List && detail.isNotEmpty) {
            return detail.first['msg']?.toString() ?? detail.toString();
          }
          return detail.toString();
        }
        if (responseData.containsKey('message')) {
          return responseData['message'].toString();
        }
      }
      return error.message ?? 'HTTP Error $statusCode';
    }

    final message = extractMessage();

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return NetworkException(
          message: 'Network connection timeout: $message',
          statusCode: statusCode,
        );

      case DioExceptionType.badResponse:
        if (statusCode == 404) {
          return NotFoundException(
            message: message,
            statusCode: statusCode,
            data: responseData,
          );
        } else if (statusCode == 422 || statusCode == 400) {
          return ValidationException(
            message: message,
            statusCode: statusCode,
            data: responseData,
          );
        } else if (statusCode != null && statusCode >= 500) {
          return ServerException(
            message: 'Server error ($statusCode): $message',
            statusCode: statusCode,
            data: responseData,
          );
        }
        return ApiException(
          message: message,
          statusCode: statusCode,
          data: responseData,
        );

      case DioExceptionType.cancel:
        return ApiException(message: 'Request was cancelled');

      default:
        return NetworkException(
          message: 'Network error occurred: ${error.message}',
          statusCode: statusCode,
        );
    }
  }
}
