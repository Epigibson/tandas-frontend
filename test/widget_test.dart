import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tanda_app/features/auth/presentation/screens/login_screen.dart';
import 'package:tanda_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Sin sesión guardada, el splash lleva al login', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TandaApp(),
      ),
    );
    expect(find.byType(TandaApp), findsOneWidget);

    // Deja correr el splash (1.4 s) y la transición de entrada
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
