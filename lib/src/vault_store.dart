import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'crypto_util.dart';
import 'models.dart';

enum VaultProfile { real, pseudo }

/// Holds the unlocked vault in memory and persists it as an encrypted file.
///
/// Persistence rules (this is what keeps entries from vanishing):
///  * every save is written to a temp file, flushed, then renamed - a crash or
///    a kill can never leave a half-written vault
///  * the previous good file is kept as `<name>.bak` and is used automatically
///    when the main file fails to decrypt
///  * nothing is ever written while locked or read-only
class VaultStore extends ChangeNotifier {
  VaultStore._();

  static final VaultStore instance = VaultStore._();

  static const String _metaName = 'meta.json';
  static const String _pseudoPin = 'lemon-pseudo-decoy-v1';

  /// Test hook: point the store at a scratch directory instead of the
  /// platform's application support folder.
  static Directory? directoryOverride;

  Directory? _dir;
  Map<String, dynamic> _meta = <String, dynamic>{};
  Uint8List? _key;

  VaultProfile profile = VaultProfile.real;
  bool setupDone = false;
  bool unlocked = false;
  bool readOnly = false;
  bool busy = false;
  /// Exposed as a ValueNotifier so the app theme can be rebuilt without
  /// touching the navigation tree.
  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.system);

  final List<VaultEntry> entries = <VaultEntry>[];
  final List<TotpEntry> totps = <TotpEntry>[];

  String get _vaultName => '${profile.name}.vault';

  String _path(String name) => '${_dir!.path}${Platform.pathSeparator}$name';

  Future<void> init() async {
    try {
      final Directory dir =
          directoryOverride ?? await getApplicationSupportDirectory();
      if (!await dir.exists()) await dir.create(recursive: true);
      _dir = dir;
    } catch (_) {
      _dir = Directory.systemTemp;
    }

    try {
      final File file = File(_path(_metaName));
      if (await file.exists()) {
        final Object? raw = jsonDecode(await file.readAsString());
        if (raw is Map<String, dynamic>) _meta = raw;
      }
    } catch (_) {
      _meta = <String, dynamic>{};
    }

    setupDone = _meta['setup'] == true;
    themeMode.value = switch (_meta['theme'] as String? ?? 'system') {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    notifyListeners();
  }

  // ---------------------------------------------------------------- meta I/O

  Future<void> _saveMeta() async {
    try {
      final File file = File(_path(_metaName));
      final File tmp = File('${file.path}.tmp');
      await tmp.writeAsString(jsonEncode(_meta), flush: true);
      final File bak = File('${file.path}.bak');
      if (await file.exists()) {
        if (await bak.exists()) await bak.delete();
        await file.rename(bak.path);
      }
      await tmp.rename(file.path);
    } catch (_) {
      // keep going - the vault file itself is the source of truth
    }
  }

  // ------------------------------------------------------------------ unlock

  Future<bool> createPin(String pin) async {
    final Uint8List salt = randomBytes(16);
    final Uint8List key = await deriveKeyOffThread(pin, salt);

    _meta['setup'] = true;
    _meta['saltReal'] = b64Encode(salt);
    _meta['verReal'] = await makeVerifier(key);
    await _saveMeta();

    _key = key;
    profile = VaultProfile.real;
    readOnly = false;
    entries.clear();
    totps.clear();
    final bool ok = await _persist();
    unlocked = true;
    notifyListeners();
    return ok;
  }

  /// Correct PIN -> real vault. Any wrong PIN -> the pseudo decoy vault.
  Future<bool> unlock(String pin) async {
    final String? saltB64 = _meta['saltReal'] as String?;
    final String? verifier = _meta['verReal'] as String?;

    if (saltB64 != null && verifier != null) {
      try {
        final Uint8List key = await deriveKeyOffThread(pin, b64Decode(saltB64));
        if (await checkVerifier(key, verifier)) {
          _key = key;
          profile = VaultProfile.real;
          readOnly = false;
          await _load();
          unlocked = true;
          notifyListeners();
          return true;
        }
      } catch (_) {
        // fall through to the decoy vault
      }
    }

    await _openPseudo();
    return true;
  }

  Future<void> _openPseudo() async {
    String? saltB64 = _meta['saltPseudo'] as String?;
    if (saltB64 == null) {
      saltB64 = b64Encode(randomBytes(16));
      _meta['saltPseudo'] = saltB64;
      await _saveMeta();
    }
    final Uint8List key = await deriveKeyOffThread(_pseudoPin, b64Decode(saltB64));
    _key = key;
    profile = VaultProfile.pseudo;
    readOnly = false;
    await _load();
    unlocked = true;
    notifyListeners();
  }

  Future<void> lock() async {
    _key = null;
    unlocked = false;
    readOnly = false;
    entries.clear();
    totps.clear();
    profile = VaultProfile.real;
    notifyListeners();
  }

  /// Changing the PIN inside the decoy vault must not touch the real vault,
  /// so there it simply reports success.
  Future<bool> changePin(String current, String next) async {
    if (readOnly) return false;
    if (profile != VaultProfile.real) {
      await Future<void>.delayed(const Duration(milliseconds: 250));
      return true;
    }
    final Uint8List? key = _key;
    if (key == null) return false;

    final String? saltB64 = _meta['saltReal'] as String?;
    final String? verifier = _meta['verReal'] as String?;
    if (saltB64 == null || verifier == null) return false;

    final Uint8List oldKey = await deriveKeyOffThread(current, b64Decode(saltB64));
    if (!await checkVerifier(oldKey, verifier)) return false;

    final Uint8List salt = randomBytes(16);
    final Uint8List newKey = await deriveKeyOffThread(next, salt);
    _key = newKey;
    final bool ok = await _persist();
    if (!ok) {
      _key = key;
      return false;
    }
    _meta['saltReal'] = b64Encode(salt);
    _meta['verReal'] = await makeVerifier(newKey);
    await _saveMeta();
    return true;
  }

  Future<void> wipe() async {
    for (final VaultProfile p in VaultProfile.values) {
      for (final String suffix in <String>['.vault', '.vault.bak', '.vault.tmp']) {
        try {
          final File file = File(_path('${p.name}$suffix'));
          if (await file.exists()) await file.delete();
        } catch (_) {}
      }
    }
    try {
      for (final String name in <String>[
        _metaName,
        '$_metaName.bak',
        '$_metaName.tmp'
      ]) {
        final File file = File(_path(name));
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    _meta = <String, dynamic>{};
    setupDone = false;
    themeMode.value = ThemeMode.system;
    await lock();
  }

  Future<void> setTheme(ThemeMode mode) async {
    themeMode.value = mode;
    _meta['theme'] = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    notifyListeners();
    await _saveMeta();
  }

  // ------------------------------------------------------------------ mutations

  Future<bool> addEntry(VaultEntry entry) async {
    entries.add(entry);
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  Future<bool> updateEntry(VaultEntry entry) async {
    final int index = entries.indexWhere((e) => e.id == entry.id);
    if (index >= 0) entries[index] = entry;
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  Future<bool> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  Future<bool> addTotp(TotpEntry entry) async {
    totps.add(entry);
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  Future<bool> updateTotp(TotpEntry entry) async {
    final int index = totps.indexWhere((t) => t.id == entry.id);
    if (index >= 0) totps[index] = entry;
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  Future<bool> deleteTotp(String id) async {
    totps.removeWhere((t) => t.id == id);
    final bool ok = await _persist();
    notifyListeners();
    return ok;
  }

  // ------------------------------------------------------------- file handling

  Future<bool> _persist() async {
    final Uint8List? key = _key;
    if (key == null || readOnly) return false;
    try {
      final Map<String, dynamic> map = <String, dynamic>{
        'version': 1,
        'entries': entries.map((e) => e.toJson()).toList(),
        'totps': totps.map((t) => t.toJson()).toList(),
      };
      final Uint8List data = await encryptBytes(
        key,
        Uint8List.fromList(utf8.encode(jsonEncode(map))),
      );

      final File main = File(_path(_vaultName));
      final File tmp = File('${main.path}.tmp');
      await tmp.writeAsBytes(data, flush: true);

      // Atomic swap: the vault only ever appears complete or not at all.
      await tmp.rename(main.path);

      // Keep a mirror of the newest good state. If the main file is ever
      // corrupted, the backup restores exactly what was last saved.
      try {
        final File bak = File('${main.path}.bak');
        await main.copy(bak.path);
      } catch (_) {
        // the backup is best effort - never fail a save because of it
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _load() async {
    final Uint8List? key = _key;
    if (key == null) return;

    final File main = File(_path(_vaultName));
    final File bak = File('${main.path}.bak');
    entries.clear();
    totps.clear();

    if (!await main.exists() && !await bak.exists()) {
      if (profile == VaultProfile.pseudo) seedPseudo(entries, totps);
      await _persist();
      return;
    }

    Uint8List? plain;
    if (await main.exists()) {
      plain = await decryptBytes(key, await main.readAsBytes());
    }
    if (plain == null && await bak.exists()) {
      plain = await decryptBytes(key, await bak.readAsBytes());
    }
    if (plain == null) {
      // Keep the files untouched so nothing is ever destroyed.
      readOnly = true;
      return;
    }

    try {
      final Object? decoded = jsonDecode(utf8.decode(plain));
      if (decoded is! Map<String, dynamic>) {
        readOnly = true;
        return;
      }
      final List<dynamic> rawEntries =
          (decoded['entries'] as List<dynamic>?) ?? const <dynamic>[];
      final List<dynamic> rawTotps =
          (decoded['totps'] as List<dynamic>?) ?? const <dynamic>[];
      for (final dynamic item in rawEntries) {
        if (item is Map) {
          entries.add(VaultEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
      for (final dynamic item in rawTotps) {
        if (item is Map) {
          totps.add(TotpEntry.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    } catch (_) {
      entries.clear();
      totps.clear();
      readOnly = true;
    }
  }

  void seedPseudo(List<VaultEntry> entryList, List<TotpEntry> totpList) {
    entryList
      ..clear()
      ..addAll(<VaultEntry>[
        VaultEntry(title: 'Mail', username: 'citrus.demo@mail.com', secret: 'Sunrise-42!', notes: ''),
        VaultEntry(title: 'Bank', username: 'demo.user', secret: 'Quiet-Harbor-1987', notes: ''),
      ]);
    totpList
      ..clear()
      ..addAll(<TotpEntry>[
        TotpEntry(label: 'demo@mail.com', issuer: 'Mail', secret: 'JBSWY3DPEHPK3PXP'),
      ]);
  }
}
