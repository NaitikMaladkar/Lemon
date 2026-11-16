# Lemon 🍋 — Citrus Manager

A lightweight, **completely offline** Android vault for passwords, passphrases and
TOTP codes, with a 4-digit PIN lock and a pseudo decoy mode.

## Features

- **Live TOTP home screen** — RFC 6238 codes with a mini **circular lemon timer**:
  one citrus slice disappears every second, the lemon is fully eaten at 30 s and
  then regrows. Tap a card to copy, or use the copy / edit / delete buttons
  beside the lemon
- **Add by QR** — CameraX + ZXing with a framed, masked scanning window (only the
  square inside the grid is scanned) or manual Base32 entry
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

## What's new in v1.3

- Fixed the **Settings crash** (a card in the layout had no `layout_width`/`layout_height`,
  so the screen threw an `InflateException` before it could draw)
- **Nothing is wiped on launch any more** — saves are written atomically
  (temp file → fsync → rename) with an automatic `.bak` fallback, the setup flag and
  PIN salt are committed synchronously, and every screen returns to the PIN screen
  when the in-memory vault is locked (previously a restored task showed an empty
  vault and silently dropped new entries)
- **Smooth everywhere** — PIN verification and PIN creation run off the main thread
  with a small spinner, dots pop when filled, keys dip on press, a wrong PIN gives a
  springy shake instead of a freeze, and activities open with a short fade + rise
- TOTP list no longer rebinds every second (only the code text updates when the
  window rolls over), so no more stutter
- Scanner masks everything outside the QR window and shows a grid + lemon brackets

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
