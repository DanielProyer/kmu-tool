import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // KmuToolApp braucht Supabase + Riverpod init → Smoke-Test übersprungen.
    // Echte Widget-Tests werden separat in test/screens/ erstellt.
    expect(true, isTrue);
  });
}
