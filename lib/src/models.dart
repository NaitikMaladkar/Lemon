import 'dart:math';

String newId() {
  final Random rnd = Random.secure();
  final List<int> bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

String _asString(Object? v, [String fallback = '']) =>
    v is String ? v : fallback;

int _asInt(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

/// A saved password or passphrase.
class VaultEntry {
  VaultEntry({
    String? id,
    required this.title,
    this.username = '',
    required this.secret,
    this.notes = '',
    this.type = passwordType,
    int? createdAt,
    int? updatedAt,
  })  : id = id ?? newId(),
        createdAt = createdAt ?? DateTime.now().millisecondsSinceEpoch,
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  static const String passwordType = 'password';
  static const String passphraseType = 'passphrase';

  final String id;
  String title;
  String username;
  String secret;
  String notes;
  String type;
  final int createdAt;
  int updatedAt;

  bool get isPassphrase => type == passphraseType;

  List<String> get words =>
      secret.split(' ').where((w) => w.trim().isNotEmpty).toList();

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'username': username,
        'secret': secret,
        'notes': notes,
        'type': type,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
      };

  factory VaultEntry.fromJson(Map<String, dynamic> json) => VaultEntry(
        id: _asString(json['id']),
        title: _asString(json['title']),
        username: _asString(json['username']),
        secret: _asString(json['secret']),
        notes: _asString(json['notes']),
        type: _asString(json['type'], passwordType),
        createdAt: _asInt(json['createdAt']),
        updatedAt: _asInt(json['updatedAt']),
      );
}

/// A TOTP account.
class TotpEntry {
  TotpEntry({
    String? id,
    required this.label,
    this.issuer = '',
    required this.secret,
    this.period = 30,
    this.digits = 6,
    this.algorithm = 'SHA1',
  }) : id = id ?? newId();

  final String id;
  String label;
  String issuer;
  String secret;
  int period;
  int digits;
  String algorithm;

  String get displayIssuer => issuer.isNotEmpty ? issuer : 'Authenticator';

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'label': label,
        'issuer': issuer,
        'secret': secret,
        'period': period,
        'digits': digits,
        'algorithm': algorithm,
      };

  factory TotpEntry.fromJson(Map<String, dynamic> json) => TotpEntry(
        id: _asString(json['id']),
        label: _asString(json['label']),
        issuer: _asString(json['issuer']),
        secret: _asString(json['secret']),
        period: _asInt(json['period'], 30),
        digits: _asInt(json['digits'], 6),
        algorithm: _asString(json['algorithm'], 'SHA1'),
      );
}
