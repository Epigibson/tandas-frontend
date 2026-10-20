import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

final biometricServiceProvider = Provider<BiometricService>((ref) => BiometricService());

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();

  /// El teléfono tiene sensor y al menos una huella (o rostro) registrada
  Future<bool> isAvailable() async {
    // En el navegador no hay huella: se entra con contraseña
    if (kIsWeb) return false;
    try {
      if (!await _auth.isDeviceSupported() || !await _auth.canCheckBiometrics) return false;
      return (await _auth.getAvailableBiometrics()).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// `true` si se validó la huella, `false` si la persona canceló.
  /// En otros casos lanza [Exception] con un mensaje listo para mostrar.
  Future<bool> authenticate(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
        authMessages: const [
          AndroidAuthMessages(
            signInTitle: 'Tanditas',
            signInHint: 'Toca el sensor de huella',
            cancelButton: 'Usar contraseña',
          ),
          IOSAuthMessages(cancelButton: 'Usar contraseña'),
        ],
      );
    } on LocalAuthException catch (e) {
      switch (e.code) {
        case LocalAuthExceptionCode.userCanceled:
        case LocalAuthExceptionCode.systemCanceled:
        case LocalAuthExceptionCode.userRequestedFallback:
        case LocalAuthExceptionCode.timeout:
          return false;
        case LocalAuthExceptionCode.temporaryLockout:
          throw Exception('Demasiados intentos. Espera unos segundos y vuelve a intentar.');
        case LocalAuthExceptionCode.biometricLockout:
          throw Exception('La huella quedó bloqueada. Desbloquea tu teléfono con tu PIN y vuelve a intentar.');
        case LocalAuthExceptionCode.noBiometricsEnrolled:
          throw Exception('Registra una huella en los ajustes de tu teléfono para usar esta opción.');
        default:
          throw Exception('No se pudo usar la huella. Entra con tu contraseña.');
      }
    }
  }
}
