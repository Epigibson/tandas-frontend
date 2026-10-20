import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:tanda_app/core/network/api_client.dart';
import 'package:tanda_app/features/tanda_creator/data/models/tanda_model.dart';
import 'package:tanda_app/features/tanda_creator/data/repositories/tanda_repository.dart';
import 'package:tanda_app/features/tanda_creator/presentation/controllers/tanda_controller.dart';
import 'package:tanda_app/features/tanda_creator/presentation/screens/create_tanda_screen.dart';
import 'package:tanda_app/features/tanda_creator/presentation/screens/join_tanda_screen.dart';

class _FakeTandaRepository extends TandaRepository {
  final Map<String, dynamic> preview;
  List<int>? joinedWith;

  _FakeTandaRepository(this.preview) : super(ApiClient());

  @override
  Future<Map<String, dynamic>> previewInvite(String inviteCode) async => preview;

  @override
  Future<Map<String, dynamic>> joinByInvite(String inviteCode, {List<int> slotNumbers = const []}) async {
    joinedWith = slotNumbers;
    throw Exception('Alguien más acaba de apartar uno de esos números. Elige otro.');
  }
}

Map<String, dynamic> _preview({required String method, bool member = false}) => {
      'id': 't1',
      'title': 'Tanda Navideña de la Familia Pérez Hernández',
      'description': 'Para los regalos',
      'organizer_name': 'María Guadalupe Hernández',
      'contribution_amount': 1500.0,
      'total_slots': 6,
      'payout_total': 9000.0,
      'frequency': 'quincenal',
      'assignment_method': method,
      'status': 'recruiting',
      'start_date': '2026-11-15T18:00:00Z',
      'already_member': member,
      'slots': [
        for (var n = 1; n <= 6; n++)
          {
            'slot_number': n,
            'taken': n == 1 || n == 4,
            'holder_first_name': n == 1 ? 'María' : (n == 4 ? 'Maximiliano' : null),
            'is_mine': false,
            'scheduled_payout_date': '2026-11-${(n + 10).toString().padLeft(2, '0')}T18:00:00Z',
          },
      ],
    };

Future<void> _pump(WidgetTester tester, Widget screen, {List overrides = const []}) async {
  await initializeDateFormatting('es_MX', null);
  // Teléfono angosto con la letra del sistema al 130 %
  tester.view.physicalSize = const Size(360, 780);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          locale: const Locale('es', 'MX'),
          supportedLocales: const [Locale('es', 'MX')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: screen,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('elección libre: no deja entrar sin número y arma el botón con lo elegido', (tester) async {
    final repo = _FakeTandaRepository(_preview(method: 'first_come'));
    await _pump(
      tester,
      const JoinTandaScreen(inviteCode: 'TANDA-ABC123'),
      overrides: [tandaRepositoryProvider.overrideWithValue(repo)],
    );

    expect(tester.takeException(), isNull);
    final button = tester.widget<ElevatedButton>(find.widgetWithText(ElevatedButton, 'Elige tu número'));
    expect(button.onPressed, isNull);

    // Los apartados no se pueden tocar
    await tester.scrollUntilVisible(find.text('#4'), 200);
    await tester.tap(find.text('#4'));
    await tester.pump();
    expect(find.widgetWithText(ElevatedButton, 'Elige tu número'), findsOneWidget);

    await tester.ensureVisible(find.text('#3'));
    await tester.tap(find.text('#3'));
    await tester.pump();
    expect(find.text('Entrar con el #3'), findsOneWidget);

    await tester.ensureVisible(find.text('#6'));
    await tester.tap(find.text('#6'));
    await tester.pump();
    expect(find.text('Entrar con 2 números'), findsOneWidget);

    // Si otro ganó el número, se avisa y se limpia la selección
    await tester.tap(find.text('Entrar con 2 números'));
    await tester.pumpAndSettle();
    expect(repo.joinedWith, [3, 6]);
    expect(find.textContaining('Alguien más acaba de apartar'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Elige tu número'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sorteo: explica el sorteo y no muestra el tablero', (tester) async {
    await _pump(
      tester,
      const JoinTandaScreen(inviteCode: 'TANDA-ABC123'),
      overrides: [tandaRepositoryProvider.overrideWithValue(_FakeTandaRepository(_preview(method: 'draw')))],
    );

    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.textContaining('se define con el sorteo'), 200);
    expect(find.textContaining('se define con el sorteo'), findsOneWidget);
    expect(find.text('#3'), findsNothing);
    expect(find.text('Unirme a la tanda'), findsOneWidget);
  });

  testWidgets('si ya es miembro ofrece abrir la tanda', (tester) async {
    await _pump(
      tester,
      const JoinTandaScreen(inviteCode: 'TANDA-ABC123'),
      overrides: [
        tandaRepositoryProvider.overrideWithValue(_FakeTandaRepository(_preview(method: 'first_come', member: true))),
      ],
    );

    expect(find.text('Ya estás en esta tanda: ver tanda'), findsOneWidget);
    expect(find.text('#3'), findsNothing);
  });

  testWidgets('editar: prellena la tanda, muestra la fecha y guarda en lugar de crear', (tester) async {
    final tomorrow = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 30));
    final tanda = TandaModel(
      id: 't1',
      title: 'Tanda de prueba',
      description: 'Regalos',
      organizerId: 'u1',
      currency: 'MXN',
      contributionAmount: 750,
      totalSlots: 8,
      payoutTotal: 6000,
      frequency: 'semanal',
      assignmentMethod: 'first_come',
      status: 'recruiting',
      gracePeriodDays: 2,
      lateFeePerDay: 0,
      inviteCode: 'TANDA-ABC123',
      startDate: DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 12),
      createdAt: DateTime.now(),
    );
    await _pump(tester, CreateTandaScreen(tanda: tanda));

    expect(tester.takeException(), isNull);
    expect(find.text('Editar tanda'), findsOneWidget);
    expect(find.text('Tanda de prueba'), findsOneWidget);
    expect(find.text('750'), findsOneWidget);
    expect(find.text('8 números'), findsOneWidget);
    expect(find.textContaining(tomorrow.year.toString()), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar cambios'));
    expect(find.text('Guardar cambios'), findsOneWidget);

    // El calendario sale en español y no deja elegir días pasados
    await tester.ensureVisible(find.byIcon(Icons.access_time));
    await tester.tap(find.byIcon(Icons.access_time));
    await tester.pumpAndSettle();
    expect(find.text('Fecha de inicio de la tanda'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Elige el día 15 del mes siguiente y lo muestra en el formulario
    await tester.tap(find.text('›'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.tap(find.text('Listo'));
    await tester.pumpAndSettle();
    final next = DateTime(tomorrow.year, tomorrow.month + 1, 15);
    expect(find.textContaining('15 de ${DateFormat('MMMM', 'es_MX').format(next)}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
