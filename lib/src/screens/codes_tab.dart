import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../totp.dart';
import '../vault_store.dart';
import '../widgets/common.dart';
import '../widgets/header.dart';
import '../widgets/lemon_timer.dart';
import 'totp_editor.dart';

/// Home tab: every TOTP account with a live code and the lemon countdown.
class CodesTab extends StatefulWidget {
  const CodesTab({super.key, this.onAdd, this.onLock});

  final VoidCallback? onAdd;
  final VoidCallback? onLock;

  @override
  State<CodesTab> createState() => _CodesTabState();
}

class _CodesTabState extends State<CodesTab> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (!mounted) return;
      if (VaultStore.instance.totps.isEmpty) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final List<TotpEntry> items = VaultStore.instance.totps;
    final String subtitle = items.isEmpty
        ? 'No codes yet'
        : '${items.length} ${items.length == 1 ? 'code' : 'codes'} · live';

    return Column(
      children: <Widget>[
        LemonHeader(
          title: 'Lemon',
          subtitle: subtitle,
          actions: <Widget>[
            HeaderAction(
              icon: Icons.lock_outline_rounded,
              tooltip: 'Lock the vault',
              onTap: widget.onLock ?? () {},
            ),
          ],
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: Icons.qr_code_2_rounded,
                  title: 'No authenticator codes',
                  body: 'Tap + to scan a QR code or type a secret key by hand.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 120),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _TotpTile(entry: items[index]);
                  },
                ),
        ),
        if (VaultStore.instance.readOnly && dark)
          const SizedBox.shrink(),
      ],
    );
  }
}

class _TotpTile extends StatelessWidget {
  const _TotpTile({required this.entry});

  final TotpEntry entry;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final DateTime now = DateTime.now();
    final double progress = Totp.progress(entry.period, at: now);
    final int seconds = Totp.secondsRemaining(entry.period, at: now);
    final int counter = now.millisecondsSinceEpoch ~/ 1000 ~/ entry.period;
    final String code = Totp.code(
      entry.secret,
      at: now,
      period: entry.period,
      digits: entry.digits,
      algorithm: entry.algorithm,
    );

    return LemonCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      onTap: () => _copy(context, code),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  entry.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  entry.displayIssuer,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft,
                  ),
                ),
                const SizedBox(height: 8),
                TweenAnimationBuilder<double>(
                  key: ValueKey<int>(counter),
                  tween: Tween<double>(begin: 0.0, end: 1.0),
                  duration: const Duration(milliseconds: 260),
                  builder: (BuildContext context, double t, Widget? child) {
                    return Opacity(opacity: 0.25 + 0.75 * t, child: child);
                  },
                  child: Text(
                    Totp.pretty(code),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 25,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                      color: dark ? LemonPalette.nightCitrus : LemonPalette.leafDeep,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TweenAnimationBuilder<double>(
            key: ValueKey<int>(counter),
            tween: Tween<double>(begin: 0.72, end: 1.0),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (BuildContext context, double scale, Widget? child) {
              return Transform.scale(scale: scale, child: child);
            },
            child: LemonTimer(
              period: entry.period,
              progress: progress,
              seconds: seconds,
              size: 62,
            ),
          ),
          const SizedBox(width: 4),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _MiniAction(
                icon: Icons.copy_rounded,
                tooltip: 'Copy code',
                onTap: () => _copy(context, code),
              ),
              _MiniAction(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                onTap: () => _edit(context),
              ),
              _MiniAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                color: LemonPalette.danger,
                onTap: () => _delete(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    showSnack(context, 'Copied $code');
  }

  void _edit(BuildContext context) {
    Navigator.of(context).push(
      TotpEditor.route(existing: entry),
    );
  }

  Future<void> _delete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete code?'),
        content: Text('${entry.label} will be removed from Lemon.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await VaultStore.instance.deleteTotp(entry.id);
    }
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.onTap,
    required this.tooltip,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              icon,
              size: 17,
              color: color ?? (dark ? LemonPalette.nightInk : LemonPalette.ink),
            ),
          ),
        ),
      ),
    );
  }
}
