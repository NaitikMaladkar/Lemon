import 'package:flutter/material.dart';

import '../vault_store.dart';
import '../widgets/pin_entry.dart';
import '../widgets/pin_scaffold.dart';
import '../theme.dart';

/// First run: pick a 4-digit PIN, then confirm it. Everything is encrypted with
/// a key derived from that PIN.
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  String? _first;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final bool confirming = _first != null;

    return PinScaffold(
      title: confirming ? 'Confirm your PIN' : 'Create your PIN',
      subtitle: confirming
          ? 'Type the same four digits once more.'
          : 'Lemon keeps everything encrypted with this PIN. There is no account '
              'and nothing ever leaves your device.',
      footer: Text(
        'Any other PIN later opens a decoy vault instead.',
        style: TextStyle(
          fontSize: 11.5,
          letterSpacing: 0.3,
          color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
        ),
      ),
      child: PinEntry(
        onComplete: (String pin) async {
          if (_first == null) {
            setState(() => _first = pin);
            return null;
          }
          if (pin != _first) {
            setState(() => _first = null);
            return 'Those PINs did not match. Start again.';
          }
          final bool ok = await VaultStore.instance.createPin(pin);
          if (!ok) return 'Could not create the vault. Try again.';
          return null;
        },
      ),
    );
  }
}
