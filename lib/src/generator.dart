import 'dart:math';

import 'wordlist.dart';

/// Random password / passphrase generation. Everything is produced on-device.
class PasswordGenerator {
  const PasswordGenerator._();

  static const String _lower = 'abcdefghijkmnopqrstuvwxyz';
  static const String _upper = 'ABCDEFGHJKLMNPQRSTUVWXYZ';
  static const String _digits = '23456789';
  static const String _symbols = r'!@#$%^&*()-_=+[]{};:,.?/';

  static final Random _rnd = Random.secure();

  /// 32 characters by default, guaranteed to contain every character class.
  static String password({int length = 32}) {
    final int len = length < 4 ? 4 : length;
    final List<String> chars = <String>[
      _pick(_lower),
      _pick(_upper),
      _pick(_digits),
      _pick(_symbols),
    ];
    const String pool = _lower + _upper + _digits + _symbols;
    while (chars.length < len) {
      chars.add(_pick(pool));
    }
    chars.shuffle(_rnd);
    return chars.join();
  }

  static List<String> passphrase(int words, {bool capitalize = false}) {
    final int count = words.clamp(1, 32);
    final List<String> out = <String>[];
    String? previous;
    while (out.length < count) {
      final String word = kWordList[_rnd.nextInt(kWordList.length)];
      if (word == previous) continue;
      previous = word;
      out.add(capitalize ? '${word[0].toUpperCase()}${word.substring(1)}' : word);
    }
    return out;
  }

  static String _pick(String pool) => pool[_rnd.nextInt(pool.length)];
}
