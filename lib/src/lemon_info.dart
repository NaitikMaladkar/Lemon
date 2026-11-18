/// App identity, kept in one place so every platform shows the same version.
class LemonInfo {
  const LemonInfo._();

  static const String appName = 'Lemon';
  static const String tagline = 'Citrus Manager';
  static const String version = '1.0.0';
  static const String description =
      'A lightweight, fully offline vault for passwords, passphrases and '
      'TOTP codes. Encrypted on device, no network permission, no screenshots.';

  /// Shown in the settings "about" block.
  static const List<String> highlights = <String>[
    'Passwords, passphrases and TOTP in one place',
    'AES-256-GCM encrypted vault, key derived from your PIN',
    'Lemon slice countdown for every authenticator code',
    'Works fully offline on Android, Windows and Linux',
  ];
}
