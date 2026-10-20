import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/tanda_creator/data/models/tanda_model.dart';
import 'package:tanda_app/features/tanda_creator/data/repositories/tanda_repository.dart';

final tandaRepositoryProvider = Provider<TandaRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return TandaRepository(apiClient);
});

final invitePreviewProvider = FutureProvider.family.autoDispose<Map<String, dynamic>, String>((ref, code) {
  return ref.watch(tandaRepositoryProvider).previewInvite(code);
});

final allTandasProvider = FutureProvider.autoDispose<List<TandaModel>>((ref) {
  return ref.watch(tandaRepositoryProvider).getAllTandas();
});

final myTandasProvider = FutureProvider.autoDispose<List<TandaModel>>((ref) async {
  final repo = ref.watch(tandaRepositoryProvider);
  return await repo.getMyTandas();
});

class TandaCreatorController extends Notifier<AsyncValue<TandaModel?>> {
  @override
  AsyncValue<TandaModel?> build() {
    return const AsyncValue.data(null);
  }

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
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tandaRepositoryProvider);
      final tanda = await repository.createTanda(
        title: title,
        description: description,
        contributionAmount: contributionAmount,
        totalSlots: totalSlots,
        frequency: frequency,
        assignmentMethod: assignmentMethod,
        gracePeriodDays: gracePeriodDays,
        lateFeePerDay: lateFeePerDay,
        startDate: startDate,
      );
      state = AsyncValue.data(tanda);
      ref.invalidate(myTandasProvider);
      return tanda;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Regresa el id de la tanda para abrir su detalle
  Future<String> joinTanda(String inviteCode, {List<int> slotNumbers = const []}) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(tandaRepositoryProvider);
      final tanda = await repository.joinByInvite(inviteCode, slotNumbers: slotNumbers);
      state = const AsyncValue.data(null);
      ref.invalidate(myTandasProvider);
      return tanda['id'] as String;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> updateTanda({
    required String tandaId,
    required String title,
    String? description,
    required double contributionAmount,
    required int totalSlots,
    required String frequency,
    required String assignmentMethod,
    required DateTime startDate,
  }) async {
    final repository = ref.read(tandaRepositoryProvider);
    await repository.updateTanda(
      tandaId: tandaId,
      title: title,
      description: description,
      contributionAmount: contributionAmount,
      totalSlots: totalSlots,
      frequency: frequency,
      assignmentMethod: assignmentMethod,
      startDate: startDate,
    );
    ref.invalidate(myTandasProvider);
  }
}

final tandaCreatorControllerProvider =
    NotifierProvider<TandaCreatorController, AsyncValue<TandaModel?>>(() {
  return TandaCreatorController();
});
