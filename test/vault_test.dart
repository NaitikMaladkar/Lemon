import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon/src/vault_store.dart';
import 'package:lemon/src/crypto_util.dart';
import 'package:lemon/src/generator.dart';
import 'package:lemon/src/models.dart';
import 'package:lemon/src/totp.dart';

void main() {
  group('TOTP', () {
    // RFC 6238 test vectors (SHA1, 8 digits).
    test('matches the published SHA1 vectors', () {
      const String secret = 'GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ';
      const List<(int, String)> vectors = <(int, String)>[
        (59, '94287082'),
        (1111111109, '07081804'),
        (1111111111, '14050471'),
        (1234567890, '89005924'),
        (2000000000, '69279037'),
      ];
      for (final (int epoch, String expected) in vectors) {
        final String code = Totp.code(
          secret,
          at: DateTime.fromMillisecondsSinceEpoch(epoch * 1000, isUtc: true),
          period: 30,
          digits: 8,
        );
        expect(code, expected, reason: 'epoch $epoch');
      }
    });

    test('base32 round trip and validation', () {
      expect(Totp.isValidBase32('JBSWY3DPEHPK3PXP'), isTrue);
      expect(Totp.isValidBase32('not base32!'), isFalse);
      expect(Totp.base32Decode('JBSWY3DP').length, 5);
    });

    test('parses otpauth URIs', () {
      final entry = Totp.parseOtpAuth(
        'otpauth://totp/GitHub:dev@example.com'
        '?secret=JBSWY3DPEHPK3PXP&issuer=GitHub&period=30&digits=6',
      );
      expect(entry, isNotNull);
      expect(entry!.label, 'dev@example.com');
      expect(entry.issuer, 'GitHub');
      expect(entry.period, 30);
      expect(entry.digits, 6);
      expect(Totp.parseOtpAuth('https://example.com'), isNull);
      expect(Totp.parseOtpAuth('otpauth://totp/x?secret=!!!'), isNull);
    });

    test('progress and remaining seconds line up', () {
      const int period = 30;
      final DateTime at = DateTime.fromMillisecondsSinceEpoch(30000 * 3 + 15000);
      expect(Totp.progress(period, at: at), closeTo(0.5, 0.001));
      expect(Totp.secondsRemaining(period, at: at), 15);
    });

    test('pretty prints 6 and 8 digit codes', () {
      expect(Totp.pretty('123456'), '123 456');
      expect(Totp.pretty('12345678'), '1234 5678');
    });
  });

  group('crypto', () {
    test('AES-GCM round trip and tamper detection', () async {
      final Uint8List key = Uint8List.fromList(List<int>.generate(32, (i) => i));
      final Uint8List plain = Uint8List.fromList(utf8.encode('{"hello":"lemon"}'));
      final Uint8List sealed = await encryptBytes(key, plain);
      final Uint8List? open = await decryptBytes(key, sealed);
      expect(open, isNotNull);
      expect(utf8.decode(open!), '{"hello":"lemon"}');

      sealed[sealed.length - 1] ^= 0xFF;
      expect(await decryptBytes(key, sealed), isNull);
    });

    test('PIN derivation is deterministic and verifiers validate', () async {
      final Uint8List salt = Uint8List.fromList(List<int>.generate(16, (i) => i));
      final Uint8List a = await deriveKey('1234', salt);
      final Uint8List b = await deriveKey('1234', salt);
      expect(a, equals(b));
      expect(a.length, 32);

      final Uint8List other = await deriveKey('9999', salt);
      expect(other, isNot(equals(a)));

      final String verifier = await makeVerifier(a);
      expect(await checkVerifier(a, verifier), isTrue);
      expect(await checkVerifier(other, verifier), isFalse);
    });
  });

  group('generators', () {
    test('password is 32 chars with every character class', () {
      for (int i = 0; i < 20; i++) {
        final String pw = PasswordGenerator.password();
        expect(pw.length, 32);
        expect(pw.contains(RegExp('[a-z]')), isTrue);
        expect(pw.contains(RegExp('[A-Z]')), isTrue);
        expect(pw.contains(RegExp('[0-9]')), isTrue);
        expect(pw.contains(RegExp(r'[!@#$%^&*()\-_=+\[\]{};:,.?/]')), isTrue);
      }
    });

    test('passphrase word count is respected and unique-ish', () {
      final List<String> words = PasswordGenerator.passphrase(12);
      expect(words.length, 12);
      expect(words.toSet().length, greaterThan(9));
      expect(PasswordGenerator.passphrase(1).length, 1);
      // The cap is 64 words; anything larger is clamped down to it.
      expect(PasswordGenerator.passphrase(64).length, 64);
      expect(PasswordGenerator.passphrase(200).length,
          PasswordGenerator.maxWords);
    });
  });

  group('models', () {
    test('entries and totps survive a JSON round trip', () {
      final VaultEntry entry = VaultEntry(
        title: 'Mail',
        username: 'me@example.com',
        secret: 'S3cret!',
        notes: 'note',
        type: VaultEntry.passphraseType,
      );
      final VaultEntry copy =
          VaultEntry.fromJson(jsonDecode(jsonEncode(entry.toJson())) as Map<String, dynamic>);
      expect(copy.id, entry.id);
      expect(copy.title, entry.title);
      expect(copy.type, VaultEntry.passphraseType);

      final TotpEntry totp = TotpEntry(label: 'a', issuer: 'b', secret: 'JBSWY3DPEHPK3PXP');
      final TotpEntry totpCopy =
          TotpEntry.fromJson(jsonDecode(jsonEncode(totp.toJson())) as Map<String, dynamic>);
      expect(totpCopy.label, 'a');
      expect(totpCopy.period, 30);
      expect(totpCopy.digits, 6);
    });

    test('passphrase words split cleanly', () {
      final VaultEntry entry =
          VaultEntry(title: 'p', secret: 'one  two three', type: VaultEntry.passphraseType);
      expect(entry.words, <String>['one', 'two', 'three']);
    });
  });

  group('vault persistence', () {
    late Directory dir;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('lemon_store_test');
      VaultStore.directoryOverride = dir;
      await VaultStore.instance.init();
      await VaultStore.instance.wipe();
    });

    tearDown(() async {
      await VaultStore.instance.lock();
      VaultStore.directoryOverride = null;
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('items survive a lock/unlock cycle', () async {
      final VaultStore store = VaultStore.instance;
      expect(await store.createPin('1234'), isTrue);

      await store.addEntry(
        VaultEntry(title: 'Mail', username: 'me@x.com', secret: 'S3cret!'),
      );
      await store.addTotp(TotpEntry(label: 'dev', secret: 'JBSWY3DPEHPK3PXP'));

      await store.lock();
      expect(store.entries, isEmpty);
      expect(store.totps, isEmpty);

      await store.unlock('1234');
      expect(store.entries, hasLength(1));
      expect(store.entries.first.title, 'Mail');
      expect(store.totps, hasLength(1));
      expect(store.totps.first.label, 'dev');
    });

    test('a corrupt main file falls back to the backup copy', () async {
      final VaultStore store = VaultStore.instance;
      await store.createPin('1111');
      await store.addEntry(VaultEntry(title: 'First', secret: 'a'));
      await store.addEntry(VaultEntry(title: 'Second', secret: 'b'));
      await store.lock();

      final File main = File('${dir.path}${Platform.pathSeparator}real.vault');
      expect(await main.exists(), isTrue);
      await main.writeAsBytes(<int>[1, 2, 3, 4, 5], flush: true);

      await store.unlock('1111');
      expect(store.entries, isNotEmpty);
      expect(store.entries.any((e) => e.title == 'Second'), isTrue);
      expect(store.readOnly, isFalse);
    });

    test('wrong PIN opens the decoy vault and never the real data', () async {
      final VaultStore store = VaultStore.instance;
      await store.createPin('1234');
      await store.addEntry(VaultEntry(title: 'Real secret', secret: 'top'));
      await store.lock();

      await store.unlock('9999');
      expect(store.profile, VaultProfile.pseudo);
      expect(store.entries.any((e) => e.title == 'Real secret'), isFalse);

      await store.lock();
      await store.unlock('1234');
      expect(store.profile, VaultProfile.real);
      expect(store.entries.first.title, 'Real secret');
    });

    test('changing the PIN keeps the data readable', () async {
      final VaultStore store = VaultStore.instance;
      await store.createPin('1234');
      await store.addEntry(VaultEntry(title: 'Bank', secret: 'x'));
      expect(await store.changePin('0000', '5678'), isFalse);
      expect(await store.changePin('1234', '5678'), isTrue);

      await store.lock();
      expect(await store.unlock('1234'), isTrue);
      // wrong PIN now lands in the decoy, so check the profile
      expect(store.profile, VaultProfile.pseudo);

      await store.lock();
      await store.unlock('5678');
      expect(store.profile, VaultProfile.real);
      expect(store.entries.first.title, 'Bank');
    });
  });
}
