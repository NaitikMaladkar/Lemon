// Not part of the test suite (no _test suffix): fills a demo vault so the
// desktop build can be screenshotted.
//   flutter test test/seed_demo.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lemon/src/models.dart';
import 'package:lemon/src/vault_store.dart';

void main() {
  test('seed demo vault', () async {
    final Directory dir = Directory(
      '${Platform.environment['HOME']}/.local/share/com.lemon.lemon',
    );
    if (!await dir.exists()) await dir.create(recursive: true);
    VaultStore.directoryOverride = dir;

    final VaultStore store = VaultStore.instance;
    await store.init();
    await store.wipe();
    await store.createPin('1234');

    await store.addTotp(
      TotpEntry(label: 'dev@example.com', issuer: 'GitHub', secret: 'JBSWY3DPEHPK3PXP'),
    );
    await store.addTotp(
      TotpEntry(label: 'naitik@mail.com', issuer: 'Google', secret: 'KRSXG5CTMVRXEZLU'),
    );
    await store.addTotp(
      TotpEntry(label: 'lemon-demo', issuer: 'Cloudflare', secret: 'MFRGGZDFMZTWQ2LK'),
    );

    await store.addEntry(
      VaultEntry(title: 'GitHub', username: 'naitik', secret: 'L3mon-Citrus!2026-x9Q', notes: 'work'),
    );
    await store.addEntry(
      VaultEntry(title: 'Bank', username: 'demo.user', secret: 'Quiet-Harbor-1987'),
    );
    await store.addEntry(
      VaultEntry(
        title: 'Wi-Fi',
        username: 'home',
        secret: 'lantern coral harbor dune poppy',
        type: VaultEntry.passphraseType,
      ),
    );
    await store.addEntry(
      VaultEntry(
        title: 'Recovery',
        secret: 'copper thistle ember velvet quartz finch',
        type: VaultEntry.passphraseType,
      ),
    );

    await store.lock();
    // ignore: avoid_print
    print('seeded ${dir.path}');
  });
}
