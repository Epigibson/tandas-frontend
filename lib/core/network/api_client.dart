import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

class ApiClient {
  static const String baseUrl = 'https://tandas-backend-yf7w.onrender.com';

  final Dio _dio;

  /// Se invoca cuando el servidor rechaza el token (sesión expirada o revocada)
  void Function()? onUnauthorized;

  ApiClient({String? authToken})
      : _dio = Dio(
          BaseOptions(
            baseUrl: baseUrl,
            // Render (plan gratuito) tarda hasta ~60 s en despertar el servidor
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
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
        onError: (error, handler) {
          // Un 401 en login significa credenciales incorrectas, no sesión expirada
          final hadToken = error.requestOptions.headers.containsKey('Authorization');
          final isLogin = error.requestOptions.path.endsWith('/auth/login');
          if (error.response?.statusCode == 401 && hadToken && !isLogin) {
            onUnauthorized?.call();
          }
          return handler.next(error);
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

  /// Los comprobantes llegan como ruta relativa (/uploads/...) o como URL completa
  static String resolveFileUrl(String pathOrUrl) {
    if (pathOrUrl.startsWith('http://') || pathOrUrl.startsWith('https://')) return pathOrUrl;
    return '$baseUrl${pathOrUrl.startsWith('/') ? '' : '/'}$pathOrUrl';
  }

  /// Despierta el servidor y pre-calienta la conexión TLS en segundo plano.
  /// No se espera desde la UI, así que puede tardar lo que tarde Render en arrancar.
  Future<void> prewarmConnection() async {
    try {
      await _dio.get(
        '/ping',
        options: Options(
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 60),
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
