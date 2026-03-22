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

    expect(find.text('Welcome to GemStore!'), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Login Screen'), findsOneWidget);
  });
}
