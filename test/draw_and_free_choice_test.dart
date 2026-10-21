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
const _me = 'user-me';

class _FakeAuth extends AuthController {
  @override
  Future<UserModel?> build() async => UserModel(
        id: _me,
        phone: '5512345678',
        fullName: 'Beto Pérez',
        tandaScore: 100,
        tandasCompleted: 0,
        onTimePayments: 0,
        latePayments: 0,
      );
}

Map<String, dynamic> _tanda({
  required String method,
  required String organizerId,
  required Map<int, String?> holders,
  String? drawnAt,
}) =>
    {
      'id': _tandaId,
      'title': 'Tanda Martz',
      'organizer_id': organizerId,
      'invite_code': 'TANDA-ABC123',
      'status': 'recruiting',
      'assignment_method': method,
      'numbers_drawn_at': drawnAt,
      'payout_total': 4000,
      'slots': [
        for (final entry in holders.entries)
          {
            'id': 'slot-${entry.key}',
            'slot_number': entry.key,
            'payout_status': 'pending',
            'scheduled_payout_date': '2026-12-15T18:00:00Z',
            'user': entry.value == null
                ? null
                : {'id': entry.value, 'full_name': entry.value == _me ? 'Beto Pérez' : 'Ana López'},
          },
      ],
      'rounds': [],
    };

Future<void> _pump(WidgetTester tester, Map<String, dynamic> tanda) async {
  tester.view.physicalSize = const Size(360, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authControllerProvider.overrideWith(_FakeAuth.new),
        tandaRealtimeProvider(_tandaId).overrideWith((ref) {}),
        tandaDetailProvider(_tandaId).overrideWith((ref) async => tanda),
        tandaPaymentsProvider(_tandaId).overrideWith((ref) async => []),
      ],
      child: const MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(home: TandaDetailScreen(tandaId: _tandaId)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => initializeDateFormatting('es_MX', null));

  testWidgets('sorteo sin sortear: no se ven números, solo participantes', (tester) async {
    await _pump(
      tester,
      _tanda(method: 'draw', organizerId: 'user-ana', holders: {1: 'user-ana', 2: _me, 3: 'user-ana', 4: null}),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('Participantes (3 de 4 lugares)'), findsOneWidget);
    expect(find.text('Ana López'), findsOneWidget);
    expect(find.text('2 lugares'), findsOneWidget);
    expect(find.textContaining('Tu número se sabrá en el sorteo'), findsOneWidget);
    expect(find.textContaining('#2'), findsNothing);
    expect(find.textContaining('Los números se sortean cuando se llene'), findsOneWidget);
    expect(find.text('Apartar otro lugar'), findsOneWidget);
    // Es su único lugar y no organiza: dejarlo es salir de la tanda
    expect(find.text('Salir de la tanda'), findsOneWidget);
  });

  testWidgets('sorteo lleno: el organizador sortea antes de poder iniciar', (tester) async {
    await _pump(tester, _tanda(method: 'draw', organizerId: _me, holders: {1: _me, 2: 'user-ana'}));

    expect(find.text('Hacer el sorteo'), findsOneWidget);
    expect(find.text('Iniciar tanda'), findsNothing);
  });

  testWidgets('sorteo ya sorteado: se revelan los números y se puede iniciar', (tester) async {
    await _pump(
      tester,
      _tanda(method: 'draw', organizerId: _me, holders: {1: 'user-ana', 2: _me}, drawnAt: '2026-10-20T20:00:00Z'),
    );

    expect(find.textContaining('Participantes'), findsNothing);
    expect(find.textContaining('Tus números: #2'), findsOneWidget);
    expect(find.text('Iniciar tanda'), findsOneWidget);
  });

  testWidgets('elección libre: con un número, tocar otro libre ofrece cambiarse', (tester) async {
    await _pump(
      tester,
      _tanda(method: 'first_come', organizerId: 'user-ana', holders: {1: 'user-ana', 2: _me, 3: null, 4: null}),
    );

    await tester.tap(find.text('Número disponible').last);
    await tester.pumpAndSettle();
    expect(find.text('Cambiarme del #2 al #4'), findsOneWidget);
    expect(find.text('Apartar también el #4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elección libre: liberar el único número avisa que sales de la tanda', (tester) async {
    await _pump(
      tester,
      _tanda(method: 'first_come', organizerId: 'user-ana', holders: {1: 'user-ana', 2: _me, 3: null}),
    );

    await tester.tap(find.textContaining('Beto Pérez (Tú)'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Liberar mi número y salir de la tanda'));
    await tester.tap(find.text('Liberar mi número y salir de la tanda'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la tanda?'), findsOneWidget);
    await tester.tap(find.text('Me quedo'));
    await tester.pumpAndSettle();
    expect(find.text('¿Salir de la tanda?'), findsNothing);
  });
}
