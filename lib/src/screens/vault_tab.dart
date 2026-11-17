import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../theme.dart';
import '../vault_store.dart';
import '../widgets/common.dart';
import '../widgets/header.dart';
import 'entry_editor.dart';

/// Vault tab: passwords and passphrases in two sections.
class VaultTab extends StatelessWidget {
  const VaultTab({
    super.key,
    required this.segment,
    required this.onSegmentChanged,
  });

  final int segment;
  final ValueChanged<int> onSegmentChanged;

  @override
  Widget build(BuildContext context) {
    final List<VaultEntry> items = VaultStore.instance.entries
        .where((VaultEntry e) =>
            segment == 0
                ? e.type == VaultEntry.passwordType
                : e.type == VaultEntry.passphraseType)
        .toList();

    return Column(
      children: <Widget>[
        LemonHeader(
          title: 'Vault',
          subtitle: '${VaultStore.instance.entries.length} items · encrypted on device',
          actions: <Widget>[
            HeaderAction(
              icon: Icons.add_rounded,
              tooltip: 'Add entry',
              onTap: () => Navigator.of(context).push(
                EntryEditor.route(
                  type: segment == 0
                      ? VaultEntry.passwordType
                      : VaultEntry.passphraseType,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: <Widget>[
              Expanded(
                child: _Segment(
                  label: 'Passwords',
                  icon: Icons.key_rounded,
                  selected: segment == 0,
                  onTap: () => onSegmentChanged(0),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Segment(
                  label: 'Passphrases',
                  icon: Icons.short_text_rounded,
                  selected: segment == 1,
                  onTap: () => onSegmentChanged(1),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? EmptyState(
                  icon: segment == 0
                      ? Icons.password_rounded
                      : Icons.format_quote_rounded,
                  title: segment == 0
                      ? 'No passwords saved'
                      : 'No passphrases saved',
                  body: 'Tap + to add your first one. Everything is encrypted '
                      'with AES-256-GCM and never leaves the device.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    return _EntryTile(
                      key: ValueKey<String>(items[index].id),
                      entry: items[index],
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? (dark ? LemonPalette.nightCitrus : LemonPalette.citrus)
              : (dark ? LemonPalette.nightSurface : LemonPalette.surface),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Colors.transparent
                : (dark ? LemonPalette.nightLine : LemonPalette.line),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 17,
              color: selected
                  ? (dark ? LemonPalette.ink : Colors.white)
                  : (dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13.5,
                color: selected
                    ? (dark ? LemonPalette.ink : Colors.white)
                    : (dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EntryTile extends StatefulWidget {
  const _EntryTile({super.key, required this.entry});

  final VaultEntry entry;

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
  bool _revealed = false;
  bool _expanded = false;

  VaultEntry get entry => widget.entry;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color soft = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;

    return LemonCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      onTap: entry.isPassphrase
          ? () => setState(() => _expanded = !_expanded)
          : () => _copySecret(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: entry.isPassphrase
                        ? <Color>[
                            LemonPalette.leaf.withValues(alpha: 0.22),
                            LemonPalette.leaf.withValues(alpha: 0.10),
                          ]
                        : <Color>[
                            LemonPalette.citrus.withValues(alpha: 0.28),
                            LemonPalette.citrus.withValues(alpha: 0.12),
                          ],
                  ),
                ),
                child: Icon(
                  entry.isPassphrase ? Icons.short_text_rounded : Icons.key_rounded,
                  size: 20,
                  color: entry.isPassphrase
                      ? LemonPalette.leafDeep
                      : LemonPalette.citrusDeep,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 15),
                    ),
                    if (entry.username.isNotEmpty)
                      Text(
                        entry.username,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11.5, color: soft),
                      ),
                  ],
                ),
              ),
              CircleAction(
                icon: Icons.copy_rounded,
                tooltip: 'Copy',
                onTap: () => _copySecret(context),
              ),
              CircleAction(
                icon: Icons.edit_outlined,
                tooltip: 'Edit',
                onTap: () => Navigator.of(context).push(
                  EntryEditor.route(existing: entry),
                ),
              ),
              CircleAction(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Delete',
                color: LemonPalette.danger,
                onTap: () => _confirmDelete(context),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (!entry.isPassphrase)
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _revealed ? entry.secret : '•' * (entry.secret.length.clamp(6, 24)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                      letterSpacing: _revealed ? 0 : 2,
                      fontWeight: FontWeight.w600,
                      color: _revealed
                          ? (dark ? LemonPalette.nightInk : LemonPalette.ink)
                          : soft,
                    ),
                  ),
                ),
                CircleAction(
                  icon: _revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  tooltip: _revealed ? 'Hide' : 'Reveal',
                  onTap: () => setState(() => _revealed = !_revealed),
                ),
              ],
            )
          else ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    _expanded
                        ? '${entry.words.length} words · tap to collapse'
                        : '${entry.words.length} words · tap to expand',
                    style: TextStyle(fontSize: 11.5, color: soft),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded, size: 20, color: soft),
                ),
              ],
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: <Widget>[
                    for (int i = 0; i < entry.words.length; i++)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: dark
                              ? LemonPalette.nightSurfaceAlt
                              : LemonPalette.surfaceAlt,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: dark
                                ? LemonPalette.nightLine
                                : LemonPalette.line,
                          ),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: <InlineSpan>[
                              TextSpan(
                                text: '${i + 1} ',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: LemonPalette.citrusDeep,
                                ),
                              ),
                              TextSpan(
                                text: entry.words[i],
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: dark
                                      ? LemonPalette.nightInk
                                      : LemonPalette.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _copySecret(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: entry.secret));
    if (!context.mounted) return;
    showSnack(context, 'Copied ${entry.title}');
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Delete entry?'),
        content: Text('${entry.title} will be removed from the vault.'),
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
      await VaultStore.instance.deleteEntry(entry.id);
    }
  }
}
