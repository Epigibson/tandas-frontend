import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
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
      final message = apiErrorMessage(e, 'Error al crear la tanda');
      throw Exception(message);
    }
  }

  Future<List<TandaModel>> getMyTandas() async {
    try {
      final response = await _apiClient.dio.get('/tandas');
      final list = response.data as List<dynamic>;
      return list.map((item) => TandaModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Error al obtener tus tandas');
      throw Exception(message);
    }
  }

  /// Solo para el admin: todas las tandas de la app
  Future<List<TandaModel>> getAllTandas() async {
    try {
      final response = await _apiClient.dio.get('/tandas', queryParameters: {'all_tandas': true});
      final list = response.data as List<dynamic>;
      return list.map((item) => TandaModel.fromJson(item as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Error al obtener las tandas'));
    }
  }

  Future<Map<String, dynamic>> getTandaDetail(String tandaId) async {
    try {
      final response = await _apiClient.dio.get('/tandas/$tandaId');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Error al cargar detalles');
      throw Exception(message);
    }
  }

  /// Lo que ve quien tiene el código antes de unirse: datos de la tanda y números libres
  Future<Map<String, dynamic>> previewInvite(String inviteCode) async {
    try {
      final response = await _apiClient.dio.get('/tandas/invite/${inviteCode.trim()}');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'Código inválido'));
    }
  }

  Future<Map<String, dynamic>> joinByInvite(String inviteCode, {List<int> slotNumbers = const []}) async {
    try {
      final response = await _apiClient.dio.post(
        '/tandas/join/${inviteCode.trim()}',
        data: {'slot_numbers': slotNumbers},
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Código inválido o tanda llena');
      throw Exception(message);
    }
  }

  /// Solo antes de iniciar; el backend recalcula bolsa, turnos y fechas
  Future<Map<String, dynamic>> updateTanda({
    required String tandaId,
    required String title,
    String? description,
    required double contributionAmount,
    required int totalSlots,
    required String frequency,
    required String assignmentMethod,
    required DateTime startDate,
  }) async {
    try {
      final response = await _apiClient.dio.patch(
        '/tandas/$tandaId',
        data: {
          'title': title.trim(),
          'description': (description == null || description.trim().isEmpty) ? null : description.trim(),
          'contribution_amount': contributionAmount,
          'total_slots': totalSlots,
          'frequency': frequency,
          'assignment_method': assignmentMethod,
          'start_date': startDate.toUtc().toIso8601String(),
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo guardar la tanda'));
    }
  }

  Future<void> deleteTanda(String tandaId) async {
    try {
      await _apiClient.dio.delete('/tandas/$tandaId');
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo eliminar la tanda'));
    }
  }

  Future<Map<String, dynamic>> triggerLotteryDraw(String tandaId) async {
    try {
      final response = await _apiClient.dio.post('/tandas/$tandaId/draw');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Error al ejecutar el sorteo');
      throw Exception(message);
    }
  }
}
