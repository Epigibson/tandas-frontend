import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/tanda_creator/presentation/controllers/tanda_controller.dart';

final tandaDetailProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, tandaId) async {
  final repo = ref.watch(tandaRepositoryProvider);
  return await repo.getTandaDetail(tandaId);
});

final tandaPaymentsProvider = FutureProvider.family.autoDispose<List<dynamic>, String>((ref, tandaId) async {
  final apiClient = ref.watch(apiClientProvider);
  final response = await apiClient.dio.get('/payments/tanda/$tandaId');
  return response.data as List<dynamic>;
});

class TandaDetailActions {
  final Ref _ref;

  TandaDetailActions(this._ref);

  Future<void> submitPaymentProof({
    required String roundId,
    required String filePath,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);

    // 1. Subir archivo
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath),
    });
    final uploadRes = await apiClient.dio.post('/upload/receipt', data: formData);
    final fileUrl = uploadRes.data['url'] as String;

    // 2. Registrar pago
    await apiClient.dio.post(
      '/payments/round/$roundId/submit',
      data: {'proof_image_url': fileUrl},
    );

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
    await apiClient.dio.post(
      '/payments/$paymentId/review',
      data: {
        'approved': approved,
        'rejection_reason': ?rejectionReason,
      },
    );

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(tandaPaymentsProvider(tandaId));
  }

  Future<void> confirmPayout({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.dio.post('/slots/$slotId/confirm-payout');

    _ref.invalidate(tandaDetailProvider(tandaId));
  }

  Future<void> claimSlot({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.dio.post('/slots/$slotId/claim');

    _ref.invalidate(tandaDetailProvider(tandaId));
    _ref.invalidate(myTandasProvider);
  }

  Future<void> releaseSlot({
    required String slotId,
    required String tandaId,
  }) async {
    final apiClient = _ref.read(apiClientProvider);
    await apiClient.dio.post('/slots/$slotId/release');

    _ref.invalidate(tandaDetailProvider(tandaId));
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
