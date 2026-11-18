import 'package:flutter/material.dart';

import '../vault_store.dart';
import '../widgets/pin_entry.dart';
import '../widgets/pin_scaffold.dart';

/// Unlock. The correct PIN opens the real vault, any other 4 digits open the
/// pseudo decoy vault - the screen behaves identically either way.
class UnlockScreen extends StatelessWidget {
  const UnlockScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PinScaffold(
      title: 'Welcome back',
      subtitle: 'Enter your 4-digit PIN to open the vault.',
      footer: 'Offline · encrypted · no screenshots',
      child: PinEntry(
        hint: 'Enter your 4-digit PIN',
        onComplete: (String pin) async {
          final bool opened = await VaultStore.instance.unlock(pin);
          if (!opened) return 'Could not open the vault. Try again.';
          return null;
        },
      ),
    );
  }
}
