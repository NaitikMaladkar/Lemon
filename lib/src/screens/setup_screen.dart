import 'package:flutter/material.dart';

import '../vault_store.dart';
import '../widgets/pin_entry.dart';
import '../widgets/pin_scaffold.dart';

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
    final bool confirming = _first != null;

    return PinScaffold(
      title: confirming ? 'Confirm your PIN' : 'Create your PIN',
      subtitle: confirming
          ? 'Type the same four digits once more.'
          : 'Lemon encrypts everything with this PIN. Nothing ever leaves your '
              'device.',
      footer: 'Any other PIN later opens a decoy vault instead.',
      child: PinEntry(
        hint: confirming ? 'Repeat the four digits' : 'Choose a 4-digit PIN',
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
