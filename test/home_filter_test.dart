import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:tanda_app/core/realtime/tanda_realtime.dart';
import 'package:tanda_app/features/auth/data/models/user_model.dart';
import 'package:tanda_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:tanda_app/features/home/presentation/screens/home_screen.dart';
import 'package:tanda_app/features/tanda_creator/data/models/tanda_model.dart';
import 'package:tanda_app/features/tanda_creator/presentation/controllers/tanda_controller.dart';

class _NoUser extends AuthController {
  @override
  FutureOr<UserModel?> build() => null;
}

TandaModel _tanda(String id, String title, String status) => TandaModel(
      id: id,
      title: title,
      organizerId: 'u1',
      currency: 'MXN',
      contributionAmount: 500,
      totalSlots: 6,
      payoutTotal: 3000,
      frequency: 'quincenal',
      assignmentMethod: 'first_come',
      status: status,
      gracePeriodDays: 2,
      lateFeePerDay: 0,
      inviteCode: 'TANDA-$id',
      createdAt: DateTime(2026, 10, 1),
    );

void main() {
  testWidgets('el filtro por estado muestra solo los estados que existen y filtra la lista', (tester) async {
    await initializeDateFormatting('es_MX', null);
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final tandas = [
      _tanda('a', 'Tanda Navidad', 'active'),
      _tanda('b', 'Tanda Vacaciones', 'recruiting'),
      _tanda('c', 'Tanda Escuela', 'draft'),
      _tanda('d', 'Tanda Pasada', 'completed'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(_NoUser.new),
          myTandasProvider.overrideWith((ref) async => tandas),
          tandaRealtimeProvider.overrideWith((ref, id) {}),
        ],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
          child: MaterialApp(home: HomeScreen()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));

    expect(tester.takeException(), isNull);
    expect(find.text('Todas (4)'), findsOneWidget);
    expect(find.text('Reclutando (2)'), findsOneWidget);
    expect(find.text('Activas (1)'), findsOneWidget);
    expect(find.text('Terminadas (1)'), findsOneWidget);
    expect(find.textContaining('Canceladas'), findsNothing);
    expect(find.text('Tanda Navidad'), findsOneWidget);

    await tester.ensureVisible(find.text('Reclutando (2)'));
    await tester.pump();
    await tester.tap(find.text('Reclutando (2)'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tanda Vacaciones'), findsOneWidget);
    expect(find.text('Tanda Escuela'), findsOneWidget);
    expect(find.text('Tanda Navidad'), findsNothing);
    expect(find.text('Tanda Pasada'), findsNothing);

    await tester.ensureVisible(find.text('Terminadas (1)'));
    await tester.pump();
    await tester.tap(find.text('Terminadas (1)'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tanda Pasada'), findsOneWidget);
    expect(find.text('Tanda Vacaciones'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
