import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tanda_app/core/realtime/tanda_realtime.dart';
import 'package:tanda_app/features/auth/data/models/user_model.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/tanda_detail/presentation/controllers/tanda_detail_controller.dart';
import 'package:tanda_app/features/tanda_detail/presentation/screens/tanda_detail_screen.dart';

const _tandaId = 'tanda-1';
const _organizerId = 'org-1';

class _FakeAuthController extends AuthController {
  @override
  Future<UserModel?> build() async => UserModel(
        id: _organizerId,
        phone: '5512345678',
        fullName: 'Organizadora',
        tandaScore: 100,
        tandasCompleted: 0,
        onTimePayments: 0,
        latePayments: 0,
      );
}

Map<String, dynamic> _payment(String id, String name, String status, {double amount = 12500}) => {
      'id': id,
      'tanda_id': _tandaId,
      'round_id': 'round-1',
      'payer_user_id': 'user-$id',
      'slot_number': 12,
      'amount': amount,
      'status': status,
      'proof_image_url': 'https://example.com/receipt.jpg',
      'rejection_reason': status == 'rejected' ? 'Comprobante ilegible o monto incorrecto' : null,
      'payer': {'full_name': name},
    };

void main() {
  setUpAll(() => initializeDateFormatting('es_MX', null));

  testWidgets('el detalle de la tanda no se desborda con nombres largos y letra grande',
      (tester) async {
    // Teléfono angosto con la letra del sistema al 130 %
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_FakeAuthController.new),
          tandaRealtimeProvider(_tandaId).overrideWith((ref) {}),
          tandaDetailProvider(_tandaId).overrideWith((ref) async => {
                'id': _tandaId,
                'title': 'Tanda Familiar de Navidad con nombre larguísimo',
                'organizer_id': _organizerId,
                'invite_code': 'TANDA-ABC123',
                'status': 'active',
                'payout_total': 250000,
                'slots': [
                  for (var i = 1; i <= 12; i++)
                    {
                      'id': 'slot-$i',
                      'slot_number': i,
                      'payout_status': i < 12 ? 'confirmed' : 'pending',
                      'scheduled_payout_date': '2026-12-15T18:00:00Z',
                      'user': {
                        'id': i == 12 ? _organizerId : 'user-$i',
                        'full_name': 'María Guadalupe Hernández de la Fuente $i',
                      },
                    },
                ],
                'rounds': [
                  {
                    'id': 'round-12',
                    'round_number': 12,
                    'slot_number_beneficiary': 12,
                    'status': 'collecting',
                    'expected_amount': 250000,
                    'collected_amount': 125000,
                  },
                ],
              }),
          tandaPaymentsProvider(_tandaId).overrideWith((ref) async => [
                _payment('1', 'María Guadalupe Hernández de la Fuente Martínez', 'submitted', amount: 125000),
                _payment('2', 'Ana', 'approved'),
                _payment('3', 'José Francisco Rodríguez Villaseñor', 'rejected'),
              ]),
        ],
        child: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: const MaterialApp(home: TandaDetailScreen(tandaId: _tandaId)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Pestaña de turnos: nombres largos, turno actual con "¡Cobra ahora!" y montos de seis cifras
    expect(tester.takeException(), isNull);
    expect(find.textContaining('(Tú)'), findsWidgets);

    await tester.tap(find.text('Aportaciones'));
    await tester.pumpAndSettle();

    // Si algo se desborda, Flutter lanza una excepción de overflow y el test falla
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Ronda 12'), findsNWidgets(3));
    expect(find.text('Aprobar'), findsOneWidget);
    expect(find.text('Ver comprobante'), findsNWidgets(3));
  });
}
