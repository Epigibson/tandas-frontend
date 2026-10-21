import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return AuthRepository(apiClient);
});

class AuthController extends AsyncNotifier<UserModel?> {
  @override
  FutureOr<UserModel?> build() async {
    final repository = ref.watch(authRepositoryProvider);
    ref.read(apiClientProvider).onUnauthorized = () {
      if (state.value != null) logout();
    };

    final cachedUser = await repository.getCachedUser();
    if (cachedUser != null) {
      // Valida el token y trae score/estadísticas frescas sin bloquear el arranque
      unawaited(_refreshUser(repository));
    }
    return cachedUser;
  }

  Future<void> _refreshUser(AuthRepository repository) async {
    final freshUser = await repository.refreshCurrentUser();
    if (freshUser != null && ref.mounted && state.value != null) {
      state = AsyncValue.data(freshUser);
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? email,
    String? clabe,
    String? bankName,
  }) async {
    final user = await ref.read(authRepositoryProvider).updateProfile(
          fullName: fullName,
          email: email,
          clabe: clabe,
          bankName: bankName,
        );
    state = AsyncValue.data(user);
  }

  Future<void> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(
        phoneOrEmail: phoneOrEmail,
        password: password,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> register({
    required String phone,
    String? email,
    required String fullName,
    required String password,
    String? clabe,
    String? bankName,
  }) async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.register(
        phone: phone,
        email: email,
        fullName: fullName,
        password: password,
        clabe: clabe,
        bankName: bankName,
      );
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  /// Entrar con la llave del teléfono. La UI debe validar la huella antes de llamarlo.
  Future<void> loginWithDevice() async {
    try {
      final user = await ref.read(authRepositoryProvider).loginWithDevice();
      state = AsyncValue.data(user);
    } catch (e) {
      ref.invalidate(biometricAccountProvider);
      state = const AsyncValue.data(null);
      rethrow;
    }
  }

  Future<void> resetPassword({
    required String phoneOrEmail,
    required String code,
    required String newPassword,
  }) async {
    final user = await ref.read(authRepositoryProvider).resetPassword(
          phoneOrEmail: phoneOrEmail,
          code: code,
          newPassword: newPassword,
        );
    ref.invalidate(biometricAccountProvider);
    state = AsyncValue.data(user);
  }

  /// La huella sobrevive al logout a propósito: es lo que permite volver a entrar sin contraseña
  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});

/// Cuenta con huella activada en este teléfono (null si no hay)
final biometricAccountProvider = FutureProvider.autoDispose<BiometricAccount?>((ref) {
  return ref.watch(authRepositoryProvider).getBiometricAccount();
});

/// El login con contraseña lo prende para que el Home ofrezca activar la huella una sola vez
class BiometricOfferController extends Notifier<bool> {
  @override
  bool build() => false;

  void request() => state = true;

  void consume() => state = false;
}

final biometricOfferProvider = NotifierProvider<BiometricOfferController, bool>(BiometricOfferController.new);
