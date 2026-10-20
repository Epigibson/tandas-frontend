import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_error.dart';
import '../../auth/presentation/controllers/auth_controller.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

/// Endpoints `/admin`: el backend solo los responde a cuentas con `is_superuser`
class AdminRepository {
  final ApiClient _apiClient;

  AdminRepository(this._apiClient);

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _apiClient.dio.get('/admin/users', queryParameters: {'q': query.trim()});
      return (response.data as List<dynamic>).cast<Map<String, dynamic>>();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo buscar'));
    }
  }

  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> changes) async {
    try {
      final response = await _apiClient.dio.patch('/admin/users/$userId', data: changes);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudieron guardar los datos'));
    }
  }

  Future<String> createResetCode(String userId) async {
    try {
      final response = await _apiClient.dio.post('/admin/users/$userId/reset-code');
      return response.data['code'] as String;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo generar el código'));
    }
  }
}
