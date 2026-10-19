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
    return await repository.getCachedUser();
  }

  Future<void> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.login(
        phoneOrEmail: phoneOrEmail,
        password: password,
      );
    });
    if (state.hasError) {
      throw state.error!;
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
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(authRepositoryProvider);
      return await repository.register(
        phone: phone,
        email: email,
        fullName: fullName,
        password: password,
        clabe: clabe,
        bankName: bankName,
      );
    });
    if (state.hasError) {
      throw state.error!;
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(null);
  }
}

final authControllerProvider = AsyncNotifierProvider<AuthController, UserModel?>(() {
  return AuthController();
});
