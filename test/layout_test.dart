import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lemon/src/screens/setup_screen.dart';
import 'package:lemon/src/screens/unlock_screen.dart';
import 'package:lemon/src/theme.dart';
import 'package:lemon/src/vault_store.dart';
import 'package:lemon/src/widgets/pin_entry.dart';

/// Layout + flow checks that run without disk or plugins.
void main() {
  Widget wrap(Widget child, Size size) {
    return MediaQuery(
      data: MediaQueryData(size: size),
      child: MaterialApp(
        theme: LemonTheme.light(),
        home: child,
      ),
    );
  }

  Future<void> typePin(WidgetTester tester, String pin) async {
    for (final String digit in pin.split('')) {
      await tester.tap(find.text(digit).last);
      await tester.pump(const Duration(milliseconds: 60));
    }
    await tester.pump(const Duration(milliseconds: 250));
  }

  group('PIN screens fit the viewport', () {
    // Covered: small Android (360x640), tall modern phone, and a very short
    // window (landscape-ish) that used to overflow.
    const Map<String, Size> sizes = <String, Size>{
      '360x640': Size(360, 640),
      '390x844': Size(390, 844),
      '412x915': Size(412, 915),
      '320x480': Size(320, 480),
    };

    for (final MapEntry<String, Size> entry in sizes.entries) {
      testWidgets('setup screen has no overflow at ${entry.key}',
          (WidgetTester tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(const SetupScreen(), entry.value));
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        // every key is on screen and tappable
        for (final String digit in <String>['1', '2', '3', '4', '5', '6', '7', '8', '9', '0']) {
          final Rect box = tester.getRect(find.text(digit).last);
          expect(box.bottom, lessThanOrEqualTo(entry.value.height),
              reason: 'key $digit is off screen');
          expect(box.top, greaterThanOrEqualTo(0.0));
        }
      });

      testWidgets('unlock screen has no overflow at ${entry.key}',
          (WidgetTester tester) async {
        tester.view.physicalSize = entry.value;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(wrap(const UnlockScreen(), entry.value));
        await tester.pump(const Duration(milliseconds: 400));

        expect(tester.takeException(), isNull);
        expect(tester.getRect(find.text('0')).bottom,
            lessThanOrEqualTo(entry.value.height));
      });
    }
  });

  group('setup flow', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lemon_setup_test');
      VaultStore.directoryOverride = dir;
      await VaultStore.instance.init();
      await VaultStore.instance.wipe();
    });

    tearDown(() async {
      await VaultStore.instance.lock();
      VaultStore.directoryOverride = null;
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    testWidgets('mismatched confirmation returns to the first step with an error',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(wrap(const SetupScreen(), const Size(390, 844)));
      await tester.pump(const Duration(milliseconds: 300));

      await typePin(tester, '1234');
      await tester.pump(const Duration(milliseconds: 400));
      await typePin(tester, '4321');
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Create your PIN'), findsOneWidget);
      expect(find.textContaining('did not match'), findsOneWidget);
      expect(VaultStore.instance.setupDone, isFalse);
      expect(VaultStore.instance.unlocked, isFalse);
    });
  });

  // Not a widget test: key derivation is real async work, which the fake clock
  // inside testWidgets cannot drive to completion.
  test('creating a PIN marks setup as done so the gate opens the vault',
      () async {
    final Directory dir = await Directory.systemTemp.createTemp('lemon_setup');
    VaultStore.directoryOverride = dir;
    final VaultStore store = VaultStore.instance;
    await store.init();
    await store.wipe();
    expect(store.setupDone, isFalse);

    expect(await store.createPin('1234'), isTrue);

    // This is the bug that kept the setup screen on screen forever: createPin
    // unlocked the store but never flipped the flag the gate reads.
    expect(store.setupDone, isTrue, reason: 'gate would show setup again');
    expect(store.unlocked, isTrue);

    await store.lock();
    VaultStore.directoryOverride = null;
    await dir.delete(recursive: true);
  });

  testWidgets('the hint line carries the state the screen passes in',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: LemonTheme.light(),
        home: Scaffold(
          body: PinEntry(
            hint: 'Repeat the four digits',
            onComplete: (String pin) async => null,
          ),
        ),
      ),
    );
    expect(find.text('Repeat the four digits'), findsOneWidget);
  });
}
