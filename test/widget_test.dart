import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tanda_app/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: TandaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TandaApp), findsOneWidget);
  });
}
