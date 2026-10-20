import 'package:dio/dio.dart';

/// Convierte un error de red en un mensaje legible para el usuario.
/// Tolera respuestas que no son JSON (p. ej. la página HTML de un 502 de Render).
String apiErrorMessage(Object error, String fallback) {
  if (error is! DioException) return fallback;

  final data = error.response?.data;
  if (data is Map) {
    final detail = data['detail'];
    if (detail is String) return detail;
    // FastAPI regresa una lista de errores de validación en los 422
    if (detail is List && detail.isNotEmpty) {
      final first = detail.first;
      if (first is Map && first['msg'] is String) return first['msg'] as String;
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'El servidor tardó demasiado en responder. Intenta de nuevo.';
    case DioExceptionType.connectionError:
      return 'Sin conexión. Revisa tu internet.';
    default:
      return fallback;
  }
}
