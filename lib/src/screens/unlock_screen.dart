import 'package:flutter/material.dart';

import '../theme.dart';
import '../vault_store.dart';
import '../widgets/pin_entry.dart';
import '../widgets/pin_scaffold.dart';

/// Unlock. The correct PIN opens the real vault, any other 4 digits open the
/// pseudo decoy vault - the screen behaves identically either way.
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return PinScaffold(
      title: 'Welcome back',
      subtitle: 'Lemon is locked. Enter your 4-digit PIN to open the vault.',
      footer: Text(
        'Offline · encrypted · no screenshots',
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.4,
          color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
        ),
      ),
      child: PinEntry(
        onComplete: (String pin) async {
          final bool opened = await VaultStore.instance.unlock(pin);
          if (!opened) return 'Could not open the vault. Try again.';
          return null;
        },
      ),
    );
  }
}
