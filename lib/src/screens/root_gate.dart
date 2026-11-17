import 'package:flutter/material.dart';

import '../vault_store.dart';
import 'home_shell.dart';
import 'setup_screen.dart';
import 'unlock_screen.dart';

/// Switches between setup, unlock and the vault with a soft cross-fade so the
/// app never flashes or freezes between states.
///
/// It listens to the store itself - the gate must not rely on `MaterialApp`'s
/// `home` being rebuilt, because the initial route keeps its own widget tree.
class RootGate extends StatelessWidget {
  const RootGate({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: VaultStore.instance,
      builder: (BuildContext context, Widget? child) {
        final VaultStore store = VaultStore.instance;

        final Widget current;
        if (!store.setupDone) {
          current = const SetupScreen(key: ValueKey<String>('setup'));
        } else if (!store.unlocked) {
          current = const UnlockScreen(key: ValueKey<String>('unlock'));
        } else {
          current = const HomeShell(key: ValueKey<String>('home'));
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 340),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (Widget child, Animation<double> animation) {
            return FadeTransition(
              opacity: animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1.0).animate(animation),
                child: child,
              ),
            );
          },
          child: current,
        );
      },
    );
  }
}
