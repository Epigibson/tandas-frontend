import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tanda_app/core/utils/clabe.dart';
import 'package:tanda_app/core/utils/invite_link.dart';
import 'package:tanda_app/features/auth/data/models/user_model.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/auth/presentation/screens/profile_screen.dart';
import 'package:tanda_app/shared/widgets/invite_sheet.dart';

class _FakeAuth extends AuthController {
  Map<String, String?>? saved;

  @override
  FutureOr<UserModel?> build() => UserModel(
        id: 'u1',
        phone: '5512345678',
        fullName: 'Beto Pérez',
        tandaScore: 100,
        tandasCompleted: 0,
        onTimePayments: 0,
        latePayments: 0,
      );

  @override
  Future<void> updateProfile({required String fullName, String? email, String? clabe, String? bankName}) async {
    saved = {'full_name': fullName, 'email': email, 'clabe': clabe, 'bank_name': bankName};
  }
}

void main() {
  test('el enlace lleva el código y se puede pegar completo o suelto', () {
    expect(inviteLink('TANDA-A1B2C3'), 'https://tanditas.vercel.app/?unirse=TANDA-A1B2C3');
    expect(extractInviteCode('https://tanditas.vercel.app/?unirse=TANDA-A1B2C3'), 'TANDA-A1B2C3');
    expect(extractInviteCode('Entra aquí: https://tanditas.vercel.app/?unirse=tanda-a1b2c3 😀'), 'TANDA-A1B2C3');
    expect(extractInviteCode('  tanda-a1b2c3 '), 'TANDA-A1B2C3');
    final msg = inviteMessage(title: 'Navidad', inviteCode: 'TANDA-A1B2C3');
    expect(msg, contains(inviteLink('TANDA-A1B2C3')));
    expect(msg, contains('TANDA-A1B2C3'));
  });

  test('CLABE: dígito verificador y formato', () {
    expect(isValidClabe('012180001234567899'), isTrue);
    expect(isValidClabe('012180001234567890'), isFalse);
    expect(isValidClabe('1234'), isFalse);
    expect(formatClabe('012180001234567899'), '012 180 00123456789 9');
  });

  testWidgets('la hoja de invitación muestra el QR con el enlace', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => showInviteSheet(context, title: 'Navidad', inviteCode: 'TANDA-A1B2C3'),
            child: const Text('abrir'),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final qr = tester.widget<QrImageView>(find.byType(QrImageView));
    expect(qr.semanticsLabel, isNotNull);
    expect(find.text('TANDA-A1B2C3'), findsOneWidget);
    expect(find.text('Mandar invitación'), findsOneWidget);
  });

  testWidgets('mi perfil: valida la CLABE y guarda los datos bancarios', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final auth = _FakeAuth();

    await tester.pumpWidget(ProviderScope(
      overrides: [authControllerProvider.overrideWith(() => auth)],
      child: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: ProfileScreen()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Beto Pérez'), findsOneWidget);
    expect(find.text('5512345678'), findsOneWidget);

    final clabeField = find.widgetWithText(TextFormField, 'CLABE interbancaria (18 dígitos)');
    await tester.enterText(clabeField, '012180001234567890');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('La CLABE no es válida, revísala'), findsOneWidget);
    expect(auth.saved, isNull);

    await tester.enterText(clabeField, '012180001234567899');
    await tester.enterText(find.widgetWithText(TextFormField, 'Banco'), 'BBVA');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(auth.saved, {'full_name': 'Beto Pérez', 'email': null, 'clabe': '012180001234567899', 'bank_name': 'BBVA'});
    expect(tester.takeException(), isNull);
  });
}
