import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cribbage_club/app.dart';

void main() {
  testWidgets('App renders login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: App()));
    await tester.pumpAndSettle();

    // Should show login screen for unauthenticated user
    expect(find.text('Cribbage Club'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });
}
