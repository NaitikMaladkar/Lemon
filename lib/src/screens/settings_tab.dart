import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../lemon_info.dart';
import '../theme.dart';
import '../vault_store.dart';
import '../widgets/common.dart';
import '../widgets/header.dart';
import '../widgets/lemon_logo.dart';

/// Settings tab: appearance, security and data.
class SettingsTab extends StatelessWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final VaultStore store = VaultStore.instance;

    return Column(
      children: <Widget>[
        const LemonHeader(
          title: 'Settings',
          subtitle: 'Appearance, security and data',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
            children: <Widget>[
              const SectionLabel('Appearance'),
              LemonCard(
                child: Column(
                  children: <Widget>[
                    for (final ThemeMode mode in ThemeMode.values)
                      _ThemeRow(
                        mode: mode,
                        selected: store.themeMode.value == mode,
                        onTap: () => store.setTheme(mode),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('Security'),
              LemonCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: <Widget>[
                    _SettingRow(
                      icon: Icons.pin_outlined,
                      title: 'Change PIN',
                      subtitle: 'Re-encrypt the vault with a new 4-digit PIN',
                      onTap: () => _changePin(context),
                    ),
                    Divider(
                      height: 1,
                      color: dark ? LemonPalette.nightLine : LemonPalette.line,
                    ),
                    _SettingRow(
                      icon: Icons.lock_outline_rounded,
                      title: 'Lock now',
                      subtitle: 'Clear the vault from memory',
                      onTap: () => store.lock(),
                    ),
                    Divider(
                      height: 1,
                      color: dark ? LemonPalette.nightLine : LemonPalette.line,
                    ),
                    _SettingRow(
                      icon: Icons.delete_outline_rounded,
                      title: 'Erase all data',
                      subtitle: 'Delete every saved item and the PIN',
                      danger: true,
                      onTap: () => _wipe(context),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const SectionLabel('About'),
              LemonCard(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const LogoPlate(size: 64),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Lemon',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Citrus Manager · v${LemonInfo.version}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: dark
                                      ? LemonPalette.nightInkSoft
                                      : LemonPalette.inkSoft,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AboutLine(
                      icon: Icons.wifi_off_rounded,
                      text: 'Works fully offline - no network permission at all',
                    ),
                    _AboutLine(
                      icon: Icons.enhanced_encryption_outlined,
                      text: 'AES-256-GCM vault, PBKDF2-SHA256 key from your PIN',
                    ),
                    _AboutLine(
                      icon: Icons.screenshot_monitor_outlined,
                      text: 'Screenshots and screen recording are blocked',
                    ),
                    _AboutLine(
                      icon: Icons.desktop_windows_outlined,
                      text: 'Same codebase on Android, Windows and Linux',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _changePin(BuildContext pageContext) async {
    final TextEditingController current = TextEditingController();
    final TextEditingController next = TextEditingController();
    final TextEditingController confirm = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();
    bool busy = false;

    await showDialog<void>(
      context: pageContext,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Change PIN'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    _PinField(controller: current, label: 'Current PIN'),
                    const SizedBox(height: 12),
                    _PinField(controller: next, label: 'New PIN'),
                    const SizedBox(height: 12),
                    _PinField(controller: confirm, label: 'Confirm new PIN'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: busy ? null : () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: busy
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          if (next.text != confirm.text) {
                            showSnack(context, 'New PINs do not match');
                            return;
                          }
                          setState(() => busy = true);
                          final bool ok = await VaultStore.instance.changePin(
                            current.text,
                            next.text,
                          );
                          if (!context.mounted) return;
                          setState(() => busy = false);
                          if (ok) {
                            Navigator.of(context).pop();
                            showSnack(pageContext, 'PIN changed');
                          } else {
                            showSnack(context, 'Current PIN is incorrect');
                          }
                        },
                  child: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    current.dispose();
    next.dispose();
    confirm.dispose();
  }

  Future<void> _wipe(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Erase everything?'),
        content: const Text(
          'Every saved password, passphrase, TOTP code and the PIN itself will '
          'be deleted. This cannot be undone.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: LemonPalette.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Erase all'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await VaultStore.instance.wipe();
    }
  }
}

class _ThemeRow extends StatelessWidget {
  const _ThemeRow({
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (String label, IconData icon, String hint) = switch (mode) {
      ThemeMode.system => ('System default', Icons.brightness_auto_outlined, 'Follow the device theme'),
      ThemeMode.light => ('Light', Icons.light_mode_outlined, 'Bright citrus cream'),
      ThemeMode.dark => ('Dark', Icons.dark_mode_outlined, 'Deep night rind'),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  Text(
                    hint,
                    style: const TextStyle(fontSize: 11.5, color: LemonPalette.inkSoft),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? LemonPalette.citrus : Colors.transparent,
                border: Border.all(
                  color: selected ? LemonPalette.citrus : LemonPalette.inkSoft,
                  width: 1.6,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final Color color = danger ? LemonPalette.danger : Theme.of(context).colorScheme.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: <Widget>[
            Icon(icon, size: 21, color: color),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 11.5, color: LemonPalette.inkSoft),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color.withOpacity(0.6)),
          ],
        ),
      ),
    );
  }
}

class _AboutLine extends StatelessWidget {
  const _AboutLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 17, color: LemonPalette.citrusDeep),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12.5, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinField extends StatelessWidget {
  const _PinField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      obscureText: true,
      maxLength: 4,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.digitsOnly,
        LengthLimitingTextInputFormatter(4),
      ],
      decoration: InputDecoration(labelText: label, counterText: ''),
      validator: (String? value) {
        if (value == null || value.length != 4) return 'Enter 4 digits';
        return null;
      },
    );
  }
}
