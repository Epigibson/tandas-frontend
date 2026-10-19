import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://tandas-backend-yf7w.onrender.com';

  final Dio _dio;

  ApiClient({String? authToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 15),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (authToken != null) 'Authorization': 'Bearer $authToken',
            },
          ),
        ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          // Si es ping o health a nivel raíz, no prepende /api/v1
          if (options.path == '/health' || options.path == '/ping') {
            return handler.next(options);
          }
          if (!options.path.startsWith('/api/v1')) {
            final normalized = options.path.startsWith('/') ? options.path : '/${options.path}';
            options.path = '/api/v1$normalized';
          }
          return handler.next(options);
        },
      ),
    );

    // Solo loggear en debug para no consumir CPU en release
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: false,
          responseHeader: false,
        ),
      );
    }
  }

  Dio get dio => _dio;

  /// Pre-calienta el socket TLS y la conexión HTTP en segundo plano
  Future<void> prewarmConnection() async {
    try {
      await _dio.get(
        '/ping',
        options: Options(
          sendTimeout: const Duration(seconds: 3),
          receiveTimeout: const Duration(seconds: 3),
        ),
      );
    } catch (_) {
      // Falla silenciosa si no hay red inmediata
    }
  }

  void updateToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }
}
