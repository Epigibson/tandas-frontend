import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tanda_app/core/network/api_error.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/tanda_creator/presentation/controllers/tanda_controller.dart';

// Sin reintentos: si la tanda ya no existe o saliste de ella, se avisa de inmediato
// en lugar de quedarse cargando mientras Riverpod reintenta
Duration? _noRetry(int retryCount, Object error) => null;

final tandaDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, tandaId) async {
  final repo = ref.watch(tandaRepositoryProvider);
  return await repo.getTandaDetail(tandaId);
}, retry: _noRetry);

final tandaPaymentsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, tandaId) async {
  final apiClient = ref.watch(apiClientProvider);
  try {
    final response = await apiClient.dio.get('/payments/tanda/$tandaId');
    return response.data as List<dynamic>;
  } on DioException catch (e) {
    throw Exception(apiErrorMessage(e, 'Error al cargar las aportaciones'));
  }
}, retry: _noRetry);

class TandaDetailActions {
  final Ref _ref;

  TandaDetailActions(this._ref);

  /// Ejecuta una llamada al API y traduce los errores de red a mensajes legibles
  Future<T> _guard<T>(String fallback, Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, fallback));
    }
  }

  Future<void> submitPaymentProof({
    required String roundId,
    required XFile file,
    required String tandaId,
    String? payerUserId, // el organizador o el admin aporta a nombre de alguien más
  }) async {
    final apiClient = _ref.read(apiClientProvider);

    await _guard('Error al subir el comprobante', () async {
      // 1. Subir archivo
      final formData = FormData.fromMap({
        // Sin contentType Dio manda application/octet-stream y el backend lo rechaza
        // Con bytes funciona igual en el teléfono y en el navegador, donde no hay rutas de archivo
        'file': MultipartFile.fromBytes(
          await file.readAsBytes(),
          filename: file.name,
          contentType: (file.mimeType != null ? DioMediaType.parse(file.mimeType!) : null) ??
              MultipartFile.lookupMediaType(file.name) ??
              DioMediaType('image', 'jpeg'),
        ),
      });
      final uploadRes = await apiClient.dio.post('/upload/receipt', data: formData);
      final fileUrl = uploadRes.data['url'] as String;

      // 2. Registrar pago
      await apiClient.dio.post(
        '/payments/round/$roundId/submit',
        data: {'proof_image_url': fileUrl, 'payer_user_id': ?payerUserId},
      );
    });

    // 3. Invalidar providers para refrescar la pantalla
    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(tandaPaymentsProvider(tandaId));
  }

  Future<void> reviewPayment({
    required String paymentId,
    required bool approved,
    String? rejectionReason,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard(
      'Error al revisar el pago',
      () => apiClient.dio.post(
        '/payments/$paymentId/review',
        data: {
          'approved': approved,
          'rejection_reason': ?rejectionReason,
        },
      ),
    );

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(tandaPaymentsProvider(tandaId));
  }

  Future<void> confirmPayout({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard('Error al confirmar la entrega', () => apiClient.dio.post('/slots/$slotId/confirm-payout'));

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  Future<void> claimSlot({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard('No se pudo apartar el turno', () => apiClient.dio.post('/slots/$slotId/claim'));

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  /// Organizador o admin: pone a una persona en un número libre
  Future<void> assignSlot({
    required String slotId,
    required String userId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard(
      'No se pudo asignar el turno',
      () => apiClient.dio.put('/slots/$slotId/assign-user', queryParameters: {'user_id': userId}),
    );

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  /// Elección libre: cambia de número en un solo paso
  Future<void> moveSlot({
    required String slotId,
    required int toNumber,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard(
      'No se pudo cambiar de número',
      () => apiClient.dio.post('/slots/$slotId/move', data: {'slot_number': toNumber}),
    );

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  Future<void> releaseSlot({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard('No se pudo liberar el turno', () => apiClient.dio.post('/slots/$slotId/release'));

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  /// El organizador genera un código de 30 min para que un participante cambie su contraseña
  Future<String> createPasswordResetCode({
    required String tandaId,
    required String userId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    final response = await _guard(
      'No se pudo generar el código',
      () => apiClient.dio.post('/tandas/$tandaId/members/$userId/reset-code'),
    );
    return response.data['code'] as String;
  }

  Future<void> startTanda({
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await _guard('No se pudo iniciar la tanda', () => apiClient.dio.post('/tandas/$tandaId/start'));

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  Future<void> deleteTanda({
    required String tandaId,
  }) async {
    await _ref.read(tandaRepositoryProvider).deleteTanda(tandaId);
    _ref.invalidate(myTandasProvider);
  }

  Future<void> triggerDraw({
    required String tandaId,
  }) async {
    final repo = _ref.read(tandaRepositoryProvider);
    await repo.triggerLotteryDraw(tandaId);
    _ref.invalidate(tandaDetailProvider(tandaId));
  }
}

final tandaDetailActionsProvider = Provider<TandaDetailActions>((ref) {
  return TandaDetailActions(ref);
});
