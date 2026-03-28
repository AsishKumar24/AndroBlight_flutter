import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:androblight/core/theme.dart';

void main() {
  testWidgets('dark theme smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: Center(child: Text('AndroBlight')),
        ),
      ),
    );
    expect(find.text('AndroBlight'), findsOneWidget);
  });
}
