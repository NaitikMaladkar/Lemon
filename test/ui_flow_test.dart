import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon/src/theme.dart';
import 'package:lemon/src/widgets/lemon_timer.dart';
import 'package:lemon/src/widgets/pin_entry.dart';

/// Pure UI checks - no disk, no plugins, so they stay fast and deterministic.
void main() {
  Widget wrap(Widget child, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: brightness == Brightness.dark ? LemonTheme.dark() : LemonTheme.light(),
      home: Scaffold(body: child),
    );
  }

  testWidgets('PIN entry collects four digits and reports them', (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onComplete: (String pin) async {
            submitted = pin;
            return null;
          },
        ),
      ),
    );

    for (final String digit in <String>['1', '2', '3', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pump(const Duration(milliseconds: 300));

    expect(submitted, '1234');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a wrong PIN shows an error and clears the dots', (WidgetTester tester) async {
    int attempts = 0;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onComplete: (String pin) async {
            attempts++;
            return 'Wrong PIN';
          },
        ),
      ),
    );

    for (final String digit in <String>['9', '9', '9', '9']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 80));
    }
    await tester.pump(const Duration(milliseconds: 600));

    expect(attempts, 1);
    expect(find.text('Wrong PIN'), findsOneWidget);
  });

  testWidgets('backspace removes a digit before submitting', (WidgetTester tester) async {
    String? submitted;
    await tester.pumpWidget(
      wrap(
        PinEntry(
          onComplete: (String pin) async {
            submitted = pin;
            return null;
          },
        ),
      ),
    );

    for (final String digit in <String>['1', '2', '3']) {
      await tester.tap(find.text(digit));
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.text('4'));
    await tester.pump(const Duration(milliseconds: 60));
    await tester.tap(find.text('5'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(submitted, '1245');
  });

  testWidgets('lemon timer paints in light and dark', (WidgetTester tester) async {
    for (final Brightness brightness in Brightness.values) {
      await tester.pumpWidget(
        wrap(
          const Center(
            child: LemonTimer(period: 30, progress: 0.42, seconds: 17),
          ),
          brightness: brightness,
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.byType(LemonTimer), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
