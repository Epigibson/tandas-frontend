import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';

  AuthRepository(this._apiClient);

  Future<UserModel> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    try {
      // ignore: avoid_print
      print('DEBUG AUTH: Attempting login for ${phoneOrEmail.trim()}');
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': phoneOrEmail.trim(),
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );
      // ignore: avoid_print
      print('DEBUG AUTH: Response status ${response.statusCode}');
      // ignore: avoid_print
      print('DEBUG AUTH: Response data ${response.data}');

      final token = response.data['access_token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      await _persistAuth(token, user);
      // ignore: avoid_print
      print('DEBUG AUTH: User persisted successfully: ${user.fullName}');
      return user;
    } on DioException catch (e) {
      // ignore: avoid_print
      print('DEBUG AUTH: DioException $e');
      // ignore: avoid_print
      print('DEBUG AUTH: DioException response: ${e.response?.data}');
      final message = e.response?.data?['detail'] ?? 'Error de conexión con el servidor (${e.message})';
      throw Exception(message);
    } catch (e, st) {
      // ignore: avoid_print
      print('DEBUG AUTH: Unexpected error: $e\n$st');
      rethrow;
    }
  }

  Future<UserModel> register({
    required String phone,
    String? email,
    required String fullName,
    required String password,
    String? clabe,
    String? bankName,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/register',
        data: {
          'phone': phone.trim(),
          if (email != null && email.isNotEmpty) 'email': email.trim(),
          'full_name': fullName.trim(),
          'password': password,
          if (clabe != null && clabe.isNotEmpty) 'clabe': clabe.trim(),
          if (bankName != null && bankName.isNotEmpty) 'bank_name': bankName.trim(),
        },
      );

      final token = response.data['access_token'] as String;
      final userData = response.data['user'] as Map<String, dynamic>;
      final user = UserModel.fromJson(userData);

      await _persistAuth(token, user);
      return user;
    } on DioException catch (e) {
      final message = e.response?.data?['detail'] ?? 'Error al registrar usuario';
      throw Exception(message);
    }
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    final userJson = prefs.getString(_userKey);

    if (token != null && userJson != null) {
      _apiClient.updateToken(token);
      try {
        return UserModel.fromJson(jsonDecode(userJson));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  Future<UserModel?> refreshCurrentUser() async {
    try {
      final response = await _apiClient.dio.get('/users/me');
      final user = UserModel.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return user;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _apiClient.clearToken();
  }

  Future<void> _persistAuth(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _apiClient.updateToken(token);
  }
}
