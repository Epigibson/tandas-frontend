import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanda_app/core/auth/biometric_service.dart';
import 'package:tanda_app/core/network/api_client.dart';
import 'package:tanda_app/features/auth/data/repositories/auth_repository.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/auth/presentation/screens/login_screen.dart';
import 'package:tanda_app/features/auth/presentation/screens/reset_password_screen.dart';

class _FakeAuthRepository extends AuthRepository {
  final String? lastIdentifier;
  final BiometricAccount? biometricAccount;

  _FakeAuthRepository({this.lastIdentifier, this.biometricAccount}) : super(ApiClient());

  @override
  Future<String?> getLastIdentifier() async => lastIdentifier;

  @override
  Future<BiometricAccount?> getBiometricAccount() async => biometricAccount;

  @override
  Future<Never> loginWithDevice() async => throw Exception('no usado en el test');
}

class _FakeBiometricService extends BiometricService {
  final bool available;
  int prompts = 0;

  _FakeBiometricService({required this.available});

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<bool> authenticate(String reason) async {
    prompts++;
    return false; // simula que la persona canceló
  }
}

Future<void> _pumpLogin(
  WidgetTester tester, {
  required _FakeAuthRepository repository,
  required _FakeBiometricService biometric,
}) async {
  // Teléfono angosto con la letra del sistema al 130 %
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        biometricServiceProvider.overrideWithValue(biometric),
      ],
      child: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: LoginScreen()),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  testWidgets('sin huella activada: formulario con teléfono prellenado y sin desbordes', (tester) async {
    final biometric = _FakeBiometricService(available: true);
    await _pumpLogin(
      tester,
      repository: _FakeAuthRepository(lastIdentifier: '5512345678'),
      biometric: biometric,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Entrar con huella'), findsNothing);
    expect(find.text('5512345678'), findsOneWidget);
    expect(biometric.prompts, 0);

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.keyboardType, TextInputType.phone);
  });

  testWidgets('el selector Correo cambia el teclado y limpia el campo', (tester) async {
    await _pumpLogin(
      tester,
      repository: _FakeAuthRepository(lastIdentifier: '5512345678'),
      biometric: _FakeBiometricService(available: false),
    );

    await tester.tap(find.text('Correo'));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.keyboardType, TextInputType.emailAddress);
    expect(field.controller!.text, isEmpty);
  });

  testWidgets('con huella activada: saluda, ofrece el botón y la pide al abrir', (tester) async {
    final biometric = _FakeBiometricService(available: true);
    await _pumpLogin(
      tester,
      repository: _FakeAuthRepository(
        lastIdentifier: 'ana@correo.com',
        biometricAccount: const BiometricAccount(userId: 'u1', displayName: 'Ana María López'),
      ),
      biometric: biometric,
    );

    expect(tester.takeException(), isNull);
    expect(find.text('¡Hola de nuevo, Ana!'), findsOneWidget);
    expect(find.text('Entrar con huella'), findsOneWidget);
    expect(biometric.prompts, 1);
    final field = tester.widget<TextField>(find.byType(TextField).first);
    expect(field.keyboardType, TextInputType.emailAddress);
  });

  testWidgets('sin sensor de huella no se muestra el botón aunque haya cuenta guardada', (tester) async {
    await _pumpLogin(
      tester,
      repository: _FakeAuthRepository(
        biometricAccount: const BiometricAccount(userId: 'u1', displayName: 'Ana'),
      ),
      biometric: _FakeBiometricService(available: false),
    );

    expect(find.text('Entrar con huella'), findsNothing);
  });

  testWidgets('"¿Olvidaste tu contraseña?" abre la recuperación con el usuario prellenado', (tester) async {
    await _pumpLogin(
      tester,
      repository: _FakeAuthRepository(lastIdentifier: '5512345678'),
      biometric: _FakeBiometricService(available: false),
    );

    await tester.ensureVisible(find.text('¿Olvidaste tu contraseña?'));
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pumpAndSettle();

    expect(find.byType(ResetPasswordScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('5512345678'), findsOneWidget);

    // Valida el formulario vacío sin desbordes
    await tester.ensureVisible(find.text('Cambiar contraseña y entrar'));
    await tester.tap(find.text('Cambiar contraseña y entrar'));
    await tester.pump();
    expect(find.text('El código tiene 8 caracteres'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
