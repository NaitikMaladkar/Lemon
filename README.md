# Lemon 🍋 — Citrus Manager

A lightweight, **completely offline** Android vault for passwords, passphrases and
TOTP codes, with a 4-digit PIN lock and a pseudo decoy mode.

## Features

- **Live TOTP home screen** — RFC 6238 codes that refresh every second, add via
  **Scan QR** (CameraX + ZXing) or manual Base32 entry
- **Password Manager** — separate **Passwords** and **Passphrases** sections with
  name / username, tap-to-copy, edit and delete
- **Password generator** — one tap makes a unique 32-character random string
  (`a-z`, `A-Z`, `0-9`, symbols & punctuation), shown inline
- **Passphrase generator** — choose 1–32 words from a built-in English dictionary,
  shown numbered and editable per word or as a whole sequence
- **Encrypted storage** — the vault is JSON encrypted with **AES-256-GCM**; the key is
  derived from your PIN with **PBKDF2-HMAC-SHA256** (120k iterations, random salt)
- **Fully offline** — no `INTERNET` permission, no analytics, no cloud
- **No screenshots / screen recording** — `FLAG_SECURE` on every screen
- **PIN lock** — exactly 4 digits; correct PIN opens the real vault, any wrong PIN
  opens the **Pseudo** decoy vault
- **Settings** — theme (system / light / dark), change PIN, lock now, erase all data

## Build

```bash
./gradlew assembleRelease
# -> app/build/outputs/apk/release/app-release.apk
```

Requirements: JDK 17+, Android SDK 34. Kotlin, Material 3, CameraX, ZXing core.
No network permission is requested.

## Security notes

- The real vault is only decrypted in memory after a successful 4-digit PIN unlock.
- The pseudo decoy vault is a separate encrypted file, reachable by any wrong PIN,
  so a forced unlock always shows plausible fake data.
- The release APK produced by CI is signed with the debug keystore so it installs
  directly. For public distribution, add your own release keystore and signing config.

## License

MIT — do anything, no warranty.
