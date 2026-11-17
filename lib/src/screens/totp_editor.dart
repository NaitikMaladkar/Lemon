import 'package:flutter/material.dart';

import '../models.dart';
import '../theme.dart';
import '../totp.dart';
import '../vault_store.dart';
import '../widgets/common.dart';

/// Add or edit a TOTP account by typing its Base32 secret.
class TotpEditor extends StatefulWidget {
  const TotpEditor({super.key, this.existing});

  final TotpEntry? existing;

  static Route<void> route({TotpEntry? existing}) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) =>
          TotpEditor(existing: existing),
      transitionsBuilder:
          (BuildContext context, Animation<double> a, Animation<double> b, Widget child) {
        final Animation<double> curved =
            CurvedAnimation(parent: a, curve: Curves.easeOutCubic);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<TotpEditor> createState() => _TotpEditorState();
}

class _TotpEditorState extends State<TotpEditor> {
  late final TextEditingController _label;
  late final TextEditingController _issuer;
  late final TextEditingController _secret;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _label = TextEditingController(text: widget.existing?.label ?? '');
    _issuer = TextEditingController(text: widget.existing?.issuer ?? '');
    _secret = TextEditingController(text: widget.existing?.secret ?? '');
  }

  @override
  void dispose() {
    _label.dispose();
    _issuer.dispose();
    _secret.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String label = _label.text.trim();
    final String secret = _secret.text.replaceAll(' ', '').toUpperCase();

    if (label.isEmpty) {
      showSnack(context, 'Give the account a name');
      return;
    }
    if (!Totp.isValidBase32(secret)) {
      showSnack(context, 'That is not a valid Base32 secret');
      return;
    }

    setState(() => _saving = true);
    final VaultStore store = VaultStore.instance;
    final TotpEntry? existing = widget.existing;

    bool ok;
    if (existing != null) {
      existing
        ..label = label
        ..issuer = _issuer.text.trim()
        ..secret = secret;
      ok = await store.updateTotp(existing);
    } else {
      ok = await store.addTotp(
        TotpEntry(
          label: label,
          issuer: _issuer.text.trim(),
          secret: secret,
        ),
      );
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      showSnack(context, 'Could not save - vault is read only');
      return;
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final String preview = Totp.isValidBase32(_secret.text)
        ? Totp.pretty(Totp.code(_secret.text))
        : '------';

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.existing == null ? 'New code' : 'Edit code'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(widget.existing == null ? 'Add' : 'Save'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: <Widget>[
          const SectionLabel('Account'),
          TextField(
            controller: _label,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Label',
              hintText: 'you@example.com',
              prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _issuer,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Issuer (optional)',
              hintText: 'GitHub, Google...',
              prefixIcon: Icon(Icons.business_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 18),
          const SectionLabel('Secret key'),
          TextField(
            controller: _secret,
            onChanged: (_) => setState(() {}),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
            decoration: const InputDecoration(
              hintText: 'JBSWY3DPEHPK3PXP',
              prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Base32 secret from the service you are adding. Everything is '
            'computed on this device - Lemon never talks to the network.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
            ),
          ),
          const SizedBox(height: 20),
          LemonCard(
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Live preview',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.6,
                          color: dark
                              ? LemonPalette.nightInkSoft
                              : LemonPalette.inkSoft,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        preview,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: dark
                              ? LemonPalette.nightCitrus
                              : LemonPalette.leafDeep,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.timer_outlined, size: 26),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(widget.existing == null ? 'Add code' : 'Save changes'),
          ),
        ],
      ),
    );
  }
}
