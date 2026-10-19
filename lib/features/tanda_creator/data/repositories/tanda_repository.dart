import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../models/tanda_model.dart';

class TandaRepository {
  final ApiClient _apiClient;

  TandaRepository(this._apiClient);

  Future<TandaModel> createTanda({
    required String title,
    String? description,
    required double contributionAmount,
    required int totalSlots,
    required String frequency,
    required String assignmentMethod,
    int gracePeriodDays = 2,
    double lateFeePerDay = 0.0,
    DateTime? startDate,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/tandas',
        data: {
          'title': title.trim(),
          if (description != null && description.isNotEmpty) 'description': description.trim(),
          'contribution_amount': contributionAmount,
          'total_slots': totalSlots,
          'frequency': frequency,
          'assignment_method': assignmentMethod,
          'grace_period_days': gracePeriodDays,
          'late_fee_per_day': lateFeePerDay,
          'require_proof_photo': true,
          if (startDate != null) 'start_date': startDate.toUtc().toIso8601String(),
        },
      );
      return TandaModel.fromJson(response.data);
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al crear la tanda';
      throw Exception(message);
    }
  }

  Future<List<TandaModel>> getMyTandas() async {
    try {
      final response = await _apiClient.dio.get('/tandas');
      final list = response.data as List<dynamic>;
      return list.map((item) => TandaModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al obtener tus tandas';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> getTandaDetail(String tandaId) async {
    try {
      final response = await _apiClient.dio.get('/tandas/$tandaId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al cargar detalles';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> joinByInvite(String inviteCode) async {
    try {
      final response = await _apiClient.dio.post('/tandas/join/${inviteCode.trim()}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Código inválido o tanda llena';
      throw Exception(message);
    }
  }

  Future<Map<String, dynamic>> triggerLotteryDraw(String tandaId) async {
    try {
      final response = await _apiClient.dio.post('/tandas/$tandaId/draw');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al ejecutar el sorteo';
      throw Exception(message);
    }
  }
}
