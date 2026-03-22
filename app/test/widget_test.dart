import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:big_cart/screens/welcome_screen.dart';

void main() {
  testWidgets('Welcome flow navigates to login', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const WelcomeScreen(),
        routes: {
          '/login': (context) => const Scaffold(body: Text('Login Screen')),
        },
      ),
    );

    expect(find.text('Chào mừng đến với GemStore!'), findsOneWidget);
    expect(find.text('Bắt đầu'), findsOneWidget);

    await tester.tap(find.text('Bắt đầu'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
