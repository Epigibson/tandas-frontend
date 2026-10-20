import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tanda_app/core/network/api_client.dart';
import 'package:tanda_app/features/admin/data/admin_repository.dart';
import 'package:tanda_app/features/admin/presentation/screens/admin_screen.dart';
import 'package:tanda_app/features/tanda_creator/data/models/tanda_model.dart';
import 'package:tanda_app/features/tanda_creator/presentation/controllers/tanda_controller.dart';

class _FakeAdminRepository extends AdminRepository {
  Map<String, dynamic>? saved;

  _FakeAdminRepository() : super(ApiClient());

  @override
  Future<List<Map<String, dynamic>>> searchUsers(String query) async => [
        {
          'id': 'u2',
          'full_name': 'Tío Maximiliano Hernández',
          'phone': '5512345678',
          'email': null,
          'clabe': null,
          'bank_name': null,
        },
      ];

  @override
  Future<Map<String, dynamic>> updateUser(String userId, Map<String, dynamic> changes) async {
    saved = changes;
    return {'id': userId, ...changes};
  }
}

void main() {
  testWidgets('admin: ve todas las tandas y corrige los datos de una persona', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final repo = _FakeAdminRepository();
    final tandas = [
      TandaModel(
        id: 't1',
        title: 'Tanda de los tíos',
        organizerId: 'u9',
        organizerName: 'Lupita',
        currency: 'MXN',
        contributionAmount: 500,
        totalSlots: 8,
        payoutTotal: 4000,
        frequency: 'quincenal',
        assignmentMethod: 'draw',
        status: 'active',
        gracePeriodDays: 2,
        lateFeePerDay: 0,
        inviteCode: 'TANDA-1',
        createdAt: DateTime(2026, 10, 1),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          adminRepositoryProvider.overrideWithValue(repo),
          allTandasProvider.overrideWith((ref) async => tandas),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(home: AdminScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Tanda de los tíos'), findsOneWidget);
    expect(find.textContaining('Organiza Lupita'), findsOneWidget);

    await tester.tap(find.text('Personas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tío Maximiliano Hernández'));
    await tester.pumpAndSettle();
    expect(find.text('Corregir datos'), findsOneWidget);

    // Teléfono mal escrito: no se guarda
    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono (10 dígitos)'), '55123');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pump();
    expect(find.text('Deben ser 10 dígitos'), findsOneWidget);
    expect(repo.saved, isNull);

    await tester.enterText(find.widgetWithText(TextFormField, 'Teléfono (10 dígitos)'), '5598765432');
    await tester.enterText(find.widgetWithText(TextFormField, 'CLABE (opcional)'), '012180001234567891');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(repo.saved?['phone'], '5598765432');
    expect(repo.saved?['clabe'], '012180001234567891');
    expect(repo.saved?['email'], isNull);
    expect(find.text('Datos guardados ✅'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
