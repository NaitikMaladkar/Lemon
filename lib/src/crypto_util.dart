import 'dart:convert';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// All cryptography for Lemon:
///  * PIN -> 256-bit key via PBKDF2-HMAC-SHA256 (120k rounds, random salt)
///  * Vault -> AES-256-GCM (12 byte nonce prefixed to the ciphertext)
///  * PIN verifier: the key must be able to decrypt a known constant.
const int kPbkdf2Iterations = 120000;
const String kVerifyText = 'LEMON::VERIFY::v2';
const int _nonceLength = 12;
const int _macLength = 16;

Uint8List randomBytes(int length) {
  final Random rnd = Random.secure();
  return Uint8List.fromList(List<int>.generate(length, (_) => rnd.nextInt(256)));
}

String b64Encode(List<int> bytes) => base64Encode(bytes);

Uint8List b64Decode(String text) =>
    Uint8List.fromList(base64Decode(text.trim()));

/// Runs on a background isolate so the UI never freezes while deriving.
Future<Uint8List> deriveKeyOffThread(String pin, Uint8List salt) async {
  try {
    return await Isolate.run(() => deriveKey(pin, salt));
  } catch (_) {
    return deriveKey(pin, salt);
  }
}

Future<Uint8List> deriveKey(String pin, Uint8List salt) async {
  final Pbkdf2 pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: kPbkdf2Iterations,
    bits: 256,
  );
  final SecretKey key =
      await pbkdf2.deriveKeyFromPassword(password: pin, nonce: salt);
  return Uint8List.fromList(await key.extractBytes());
}

Future<Uint8List> encryptBytes(Uint8List key, Uint8List plain) async {
  final AesGcm algorithm = AesGcm.with256bits();
  final SecretBox box = await algorithm.encrypt(plain, secretKey: SecretKey(key));
  final BytesBuilder out = BytesBuilder(copy: false);
  out.add(box.nonce);
  out.add(box.cipherText);
  out.add(box.mac.bytes);
  return out.toBytes();
}

Future<Uint8List?> decryptBytes(Uint8List key, Uint8List data) async {
  if (data.length <= _nonceLength + _macLength) return null;
  try {
    final Uint8List nonce = data.sublist(0, _nonceLength);
    final Uint8List mac = data.sublist(data.length - _macLength);
    final Uint8List cipherText = data.sublist(_nonceLength, data.length - _macLength);
    final AesGcm algorithm = AesGcm.with256bits();
    final List<int> clear = await algorithm.decrypt(
      SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
      secretKey: SecretKey(key),
    );
    return Uint8List.fromList(clear);
  } catch (_) {
    return null;
  }
}

Future<String> makeVerifier(Uint8List key) async =>
    b64Encode(await encryptBytes(key, Uint8List.fromList(utf8.encode(kVerifyText))));

Future<bool> checkVerifier(Uint8List key, String verifier) async {
  try {
    final Uint8List? plain = await decryptBytes(key, b64Decode(verifier));
    if (plain == null) return false;
    return utf8.decode(plain) == kVerifyText;
  } catch (_) {
    return false;
  }
}
