# Lemon 🍋 — Citrus Manager

A lightweight, **completely offline** Android vault for passwords, passphrases and
TOTP codes, with duress (decoy) modes.

## Features

- **Password & passphrase vault** — save, edit, search, copy, reveal, delete
- **Built-in TOTP** — RFC 6238 codes that refresh every second, add via **QR scan**
  (CameraX + ZXing) or manual Base32 entry
- **Random generator** — passwords (length + charset) and passphrases (built-in word
  list), with **title** field and **auto-save** straight into the vault
- **Encrypted storage** — the vault is JSON encrypted with **AES-256-GCM**; the key is
  derived from your PIN with **PBKDF2-HMAC-SHA256** (120k iterations, random salt)
- **Fully offline** — no `INTERNET` permission, no analytics, no cloud
- **No screenshots / screen recording** — `FLAG_SECURE` on every screen
- **PIN lock with three profiles**
  - your PIN → real vault
  - any wrong PIN → **Pseudo mode** (obvious fake list)
  - secret PIN → **Secret mode** (polished, nearly-real looking decoy vault)

## Build

```bash
./gradlew assembleRelease
# -> app/build/outputs/apk/release/app-release.apk
```

Requirements: JDK 17+, Android SDK 34. Kotlin, Material 3, CameraX, ZXing core.
No network permission is requested.

## Security notes

- The real vault is only decrypted in memory after a successful PIN unlock.
- Decoy vaults are separate encrypted files; pseudo mode is reachable by any wrong PIN,
  so a forced unlock always shows plausible fake data.
- The release APK produced by CI is signed with the debug keystore so it installs
  directly. For public distribution, add your own release keystore and signing config.

## License

MIT — do anything, no warranty.
