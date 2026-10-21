import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_error.dart';
import '../models/user_model.dart';

/// Cuenta con "Entrar con huella" activado en este teléfono
class BiometricAccount {
  final String userId;
  final String displayName;

  const BiometricAccount({required this.userId, required this.displayName});
}

class AuthRepository {
  final ApiClient _apiClient;
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'cached_user';
  static const String _lastIdentifierKey = 'last_login_identifier';
  // Llave de dispositivo para la huella: el secreto va en almacenamiento seguro y sobrevive al logout
  static const String _deviceIdKey = 'biometric_device_id';
  static const String _deviceSecretKey = 'biometric_device_secret';
  static const String _biometricUserIdKey = 'biometric_user_id';
  static const String _biometricNameKey = 'biometric_user_name';

  // El token va en Keychain/Keystore; el usuario cacheado no es secreto y se queda en prefs
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  AuthRepository(this._apiClient);

  Future<UserModel> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/login',
        data: {
          'username': phoneOrEmail.trim(),
          'password': password,
        },
        options: Options(contentType: Headers.formUrlEncodedContentType),
      );

      final user = await _persistTokenResponse(response.data);
      await _rememberIdentifier(phoneOrEmail.trim());
      // Si entra otra cuenta con contraseña, la huella guardada era de alguien más
      final biometric = await getBiometricAccount();
      if (biometric != null && biometric.userId != user.id) {
        await _clearBiometricLocally();
      }
      return user;
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Error de conexión con el servidor');
      throw Exception(message);
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

      final user = await _persistTokenResponse(response.data);
      await _rememberIdentifier(phone.trim());
      return user;
    } on DioException catch (e) {
      final message = apiErrorMessage(e, 'Error al registrar usuario');
      throw Exception(message);
    }
  }

  Future<UserModel?> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    var token = await _secureStorage.read(key: _tokenKey);
    final userJson = prefs.getString(_userKey);

    // Migra tokens guardados en texto plano por versiones anteriores
    final legacyToken = prefs.getString(_tokenKey);
    if (legacyToken != null) {
      token ??= legacyToken;
      await _secureStorage.write(key: _tokenKey, value: token);
      await prefs.remove(_tokenKey);
    }

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

  /// Mi perfil: nombre, correo y datos bancarios. El teléfono no se cambia aquí (es con lo que se entra).
  Future<UserModel> updateProfile({
    required String fullName,
    String? email,
    String? clabe,
    String? bankName,
  }) async {
    try {
      final response = await _apiClient.dio.put('/users/me', data: {
        'full_name': fullName,
        'email': email,
        'clabe': clabe,
        'bank_name': bankName,
      });
      final user = UserModel.fromJson(response.data);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, jsonEncode(user.toJson()));
      return user;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudieron guardar tus datos'));
    }
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
    await _secureStorage.delete(key: _tokenKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
    _apiClient.clearToken();
  }

  // ---------------------------------------------------------------------------
  // Entrar con huella
  // ---------------------------------------------------------------------------

  Future<BiometricAccount?> getBiometricAccount() async {
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    final secret = await _secureStorage.read(key: _deviceSecretKey);
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_biometricUserIdKey);
    if (deviceId == null || secret == null || userId == null) return null;
    return BiometricAccount(userId: userId, displayName: prefs.getString(_biometricNameKey) ?? '');
  }

  /// Registra este teléfono en el backend. Requiere sesión iniciada.
  Future<void> enableBiometric(UserModel user) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/devices',
        data: {'device_name': _deviceName()},
      );
      await _secureStorage.write(key: _deviceIdKey, value: response.data['device_id'] as String);
      await _secureStorage.write(key: _deviceSecretKey, value: response.data['device_secret'] as String);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_biometricUserIdKey, user.id);
      await prefs.setString(_biometricNameKey, user.fullName);
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo activar la huella'));
    }
  }

  /// Revoca la llave en el backend (si hay sesión) y la borra del teléfono
  Future<void> disableBiometric() async {
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    if (deviceId != null) {
      try {
        await _apiClient.dio.delete('/auth/devices/$deviceId');
      } on DioException catch (_) {
        // Aunque falle la red, se borra localmente: sin el secreto la llave ya no sirve
      }
    }
    await _clearBiometricLocally();
  }

  /// Llamar solo después de que la persona validó su huella
  Future<UserModel> loginWithDevice() async {
    final deviceId = await _secureStorage.read(key: _deviceIdKey);
    final secret = await _secureStorage.read(key: _deviceSecretKey);
    if (deviceId == null || secret == null) {
      throw Exception('La huella no está activada en este teléfono.');
    }
    try {
      final response = await _apiClient.dio.post(
        '/auth/device-login',
        data: {'device_id': deviceId, 'device_secret': secret},
      );
      return await _persistTokenResponse(response.data);
    } on DioException catch (e) {
      // 401: la llave se revocó (p. ej. tras restablecer la contraseña); ya no tiene caso guardarla
      if (e.response?.statusCode == 401) await _clearBiometricLocally();
      throw Exception(apiErrorMessage(e, 'No se pudo entrar con la huella'));
    }
  }

  Future<void> _clearBiometricLocally() async {
    await _secureStorage.delete(key: _deviceIdKey);
    await _secureStorage.delete(key: _deviceSecretKey);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_biometricUserIdKey);
    await prefs.remove(_biometricNameKey);
  }

  // ---------------------------------------------------------------------------
  // Recuperar contraseña y último usuario
  // ---------------------------------------------------------------------------

  /// Cambia la contraseña con el código del organizador y deja la sesión iniciada
  Future<UserModel> resetPassword({
    required String phoneOrEmail,
    required String code,
    required String newPassword,
  }) async {
    try {
      final response = await _apiClient.dio.post(
        '/auth/reset-password',
        data: {
          'phone_or_email': phoneOrEmail.trim(),
          'code': code.trim(),
          'new_password': newPassword,
        },
      );
      final user = await _persistTokenResponse(response.data);
      await _rememberIdentifier(phoneOrEmail.trim());
      // El backend revocó todas las huellas de esta cuenta
      await _clearBiometricLocally();
      return user;
    } on DioException catch (e) {
      throw Exception(apiErrorMessage(e, 'No se pudo cambiar la contraseña'));
    }
  }

  Future<String?> getLastIdentifier() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_lastIdentifierKey);
  }

  Future<void> _rememberIdentifier(String identifier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastIdentifierKey, identifier);
  }

  Future<UserModel> _persistTokenResponse(dynamic data) async {
    final token = data['access_token'] as String;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    await _persistAuth(token, user);
    return user;
  }

  Future<void> _persistAuth(String token, UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _tokenKey, value: token);
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    _apiClient.updateToken(token);
  }
}

// dart:io no existe en web, por eso se usa defaultTargetPlatform
String _deviceName() {
  if (kIsWeb) return 'Navegador';
  return defaultTargetPlatform == TargetPlatform.iOS ? 'iPhone' : 'Android';
}
