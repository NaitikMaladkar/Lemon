import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as c;

import 'models.dart';

/// RFC 6238 TOTP plus otpauth:// URI parsing. No external services.
class Totp {
  const Totp._();

  static const String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';

  static Uint8List base32Decode(String input) {
    final String clean = input
        .trim()
        .replaceAll(' ', '')
        .replaceAll('-', '')
        .replaceAll('=', '')
        .toUpperCase();
    final List<int> out = <int>[];
    int buffer = 0;
    int bits = 0;
    for (final int codeUnit in clean.codeUnits) {
      final int value = alphabet.indexOf(String.fromCharCode(codeUnit));
      if (value < 0) continue;
      buffer = (buffer << 5) | value;
      bits += 5;
      if (bits >= 8) {
        bits -= 8;
        out.add((buffer >> bits) & 0xFF);
      }
    }
    return Uint8List.fromList(out);
  }

  static bool isValidBase32(String input) {
    final String clean =
        input.trim().replaceAll(' ', '').replaceAll('-', '').replaceAll('=', '');
    if (clean.isEmpty) return false;
    return clean
        .toUpperCase()
        .split('')
        .every((ch) => alphabet.contains(ch));
  }

  static String code(
    String secret, {
    DateTime? at,
    int period = 30,
    int digits = 6,
    String algorithm = 'SHA1',
  }) {
    final Uint8List key = base32Decode(secret);
    if (key.isEmpty) return '-' * digits;

    final int seconds = (at ?? DateTime.now()).millisecondsSinceEpoch ~/ 1000;
    final int counter = seconds ~/ (period <= 0 ? 30 : period);

    final Uint8List message = Uint8List(8);
    int value = counter;
    for (int i = 7; i >= 0; i--) {
      message[i] = value & 0xFF;
      value = value >> 8;
    }

    final c.Hash digest = switch (algorithm.toUpperCase()) {
      'SHA256' => c.sha256,
      'SHA512' => c.sha512,
      _ => c.sha1,
    };

    final List<int> hash = c.Hmac(digest, key).convert(message).bytes;
    final int offset = hash[hash.length - 1] & 0x0F;
    final int binary = ((hash[offset] & 0x7F) << 24) |
        ((hash[offset + 1] & 0xFF) << 16) |
        ((hash[offset + 2] & 0xFF) << 8) |
        (hash[offset + 3] & 0xFF);

    int mod = 1;
    for (int i = 0; i < digits; i++) {
      mod *= 10;
    }
    return (binary % mod).toString().padLeft(digits, '0');
  }

  static String pretty(String code) {
    final int size = code.length == 8 ? 4 : 3;
    final StringBuffer out = StringBuffer();
    for (int i = 0; i < code.length; i += size) {
      if (i > 0) out.write(' ');
      out.write(code.substring(i, (i + size).clamp(0, code.length)));
    }
    return out.toString();
  }

  /// 0.0 at the start of a window, 1.0 right before it rolls over.
  static double progress(int period, {DateTime? at}) {
    final int now = (at ?? DateTime.now()).millisecondsSinceEpoch;
    final int window = (period <= 0 ? 30 : period) * 1000;
    return (now % window) / window;
  }

  static int secondsRemaining(int period, {DateTime? at}) {
    final int p = period <= 0 ? 30 : period;
    final double left = (1.0 - progress(p, at: at)) * p;
    return left.ceil().clamp(1, p);
  }

  /// Parses otpauth://totp/Issuer:account?secret=...&period=30&digits=6
  static TotpEntry? parseOtpAuth(String uri) {
    if (!uri.startsWith('otpauth://')) return null;
    final String rest = uri.substring('otpauth://'.length);
    final String type = rest.split('/').first.toLowerCase();
    if (type != 'totp') return null;

    final String withoutQuery =
        rest.contains('?') ? rest.substring(0, rest.indexOf('?')) : rest;
    final String query =
        rest.contains('?') ? rest.substring(rest.indexOf('?') + 1) : '';
    final String labelPart = withoutQuery.contains('/')
        ? withoutQuery.substring(withoutQuery.indexOf('/') + 1)
        : '';
    final String label = _urlDecode(labelPart);

    final Map<String, String> params = <String, String>{};
    for (final String pair in query.split('&')) {
      if (pair.isEmpty) continue;
      final int eq = pair.indexOf('=');
      if (eq < 0) continue;
      params[_urlDecode(pair.substring(0, eq)).toLowerCase()] =
          _urlDecode(pair.substring(eq + 1));
    }

    final String? secret = params['secret'];
    if (secret == null || !isValidBase32(secret)) return null;

    String issuer = params['issuer'] ?? '';
    String account = label;
    if (label.contains(':')) {
      if (issuer.isEmpty) issuer = label.split(':').first.trim();
      account = label.split(':').sublist(1).join(':').trim();
    }

    final int digits = int.tryParse(params['digits'] ?? '') ?? 6;
    final int period = int.tryParse(params['period'] ?? '') ?? 30;
    final String algorithm = (params['algorithm'] ?? 'SHA1').toUpperCase();

    return TotpEntry(
      label: account.isEmpty ? (issuer.isEmpty ? 'Account' : issuer) : account,
      issuer: issuer,
      secret: secret.replaceAll(' ', '').toUpperCase(),
      period: period >= 5 && period <= 300 ? period : 30,
      digits: digits == 6 || digits == 8 ? digits : 6,
      algorithm: <String>['SHA1', 'SHA256', 'SHA512'].contains(algorithm)
          ? algorithm
          : 'SHA1',
    );
  }

  static String _urlDecode(String value) {
    try {
      return Uri.decodeComponent(value);
    } catch (_) {
      return value;
    }
  }

  /// Placeholder used by the encoder so any UTF-8 label round-trips.
  static String encodeLabel(String label) => Uri.encodeComponent(label);

  static String encode(String value) => base64Encode(utf8.encode(value));
}
