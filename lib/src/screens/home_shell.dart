import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../vault_store.dart';
import 'codes_tab.dart';
import 'entry_editor.dart';
import 'scanner_page.dart';
import 'settings_tab.dart';
import 'totp_editor.dart';
import 'vault_tab.dart';

/// The vault itself: three tabs plus a floating + button that adapts to the
/// current tab.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  int _vaultSegment = 0;
  late final PageController _pages = PageController();

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    setState(() => _tab = index);
    _pages.animateToPage(
      index,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _add() async {
    HapticFeedback.selectionClick();
    if (_tab == 0) {
      final String? choice = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (BuildContext context) => const _AddCodeSheet(),
      );
      if (!mounted || choice == null) return;
      if (choice == 'scan') {
        await Navigator.of(context).push(ScannerPage.route());
      } else {
        await Navigator.of(context).push(TotpEditor.route());
      }
      return;
    }
    if (_tab == 1) {
      await Navigator.of(context).push(
        EntryEditor.route(
          type: _vaultSegment == 0
              ? VaultEntry.passwordType
              : VaultEntry.passphraseType,
        ),
      );
      return;
    }
    _goTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color bg = dark ? LemonPalette.night : LemonPalette.cream;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        // The tabs draw their own bottom spacing (the nav bar floats over the
        // list), but the top must respect the status bar / notch.
        bottom: false,
        child: PageView(
          controller: _pages,
          onPageChanged: (int index) => setState(() => _tab = index),
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            AnimatedBuilder(
              animation: VaultStore.instance,
              builder: (BuildContext context, Widget? child) => CodesTab(
                onAdd: _add,
                onLock: VaultStore.instance.lock,
              ),
            ),
            AnimatedBuilder(
              animation: VaultStore.instance,
              builder: (BuildContext context, Widget? child) => VaultTab(
                segment: _vaultSegment,
                onSegmentChanged: (int value) =>
                    setState(() => _vaultSegment = value),
              ),
            ),
            const SettingsTab(),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: FloatingActionButton(
        onPressed: _add,
        elevation: 1,
        backgroundColor: dark ? LemonPalette.nightCitrus : LemonPalette.citrus,
        foregroundColor: dark ? LemonPalette.ink : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, size: 28),
        ),
      ),
      bottomNavigationBar: _LemonNav(
        index: _tab,
        onChanged: _goTo,
        background: bg,
      ),
    );
  }
}

class _LemonNav extends StatelessWidget {
  const _LemonNav({
    required this.index,
    required this.onChanged,
    required this.background,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final Color background;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<(IconData, String)> items = <(IconData, String)>[
      (Icons.timer_outlined, 'Codes'),
      (Icons.shield_outlined, 'Vault'),
      (Icons.tune_rounded, 'Settings'),
    ];

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: EdgeInsets.only(
            top: 8,
            bottom: 6 + MediaQuery.viewPaddingOf(context).bottom,
          ),
          decoration: BoxDecoration(
            color: background.withValues(alpha: dark ? 0.86 : 0.92),
            border: Border(
              top: BorderSide(
                color: dark ? LemonPalette.nightLine : LemonPalette.line,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: <Widget>[
              for (int i = 0; i < items.length; i++)
                _NavItem(
                  icon: items[i].$1,
                  label: items[i].$2,
                  selected: index == i,
                  onTap: () => onChanged(i),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color active = dark ? LemonPalette.nightCitrus : LemonPalette.citrusDeep;
    final Color idle = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? active.withValues(alpha: 0.16) : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 21, color: selected ? active : idle),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: selected ? active : idle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddCodeSheet extends StatelessWidget {
  const _AddCodeSheet();

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          decoration: BoxDecoration(
            color: dark ? LemonPalette.nightSurface : LemonPalette.surface,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: dark ? LemonPalette.nightLine : LemonPalette.line,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: dark ? LemonPalette.nightLine : LemonPalette.line,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              Text('Add a code', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                'Scan the QR your service shows, or paste the secret key.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
                ),
              ),
              const SizedBox(height: 16),
              _SheetOption(
                icon: Icons.qr_code_scanner_rounded,
                title: 'Scan QR code',
                subtitle: 'Point the camera at the authenticator QR',
                onTap: () => Navigator.of(context).pop('scan'),
              ),
              const SizedBox(height: 10),
              _SheetOption(
                icon: Icons.keyboard_alt_outlined,
                title: 'Enter manually',
                subtitle: 'Type the Base32 secret key',
                onTap: () => Navigator.of(context).pop('manual'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dark ? LemonPalette.nightSurfaceAlt : LemonPalette.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dark ? LemonPalette.nightLine : LemonPalette.line,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: LemonPalette.citrus.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: LemonPalette.citrusDeep),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
