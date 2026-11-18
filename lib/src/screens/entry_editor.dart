import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../generator.dart';
import '../models.dart';
import '../theme.dart';
import '../vault_store.dart';
import '../widgets/common.dart';

/// Add or edit a password / passphrase.
class EntryEditor extends StatefulWidget {
  const EntryEditor({
    super.key,
    this.existing,
    this.type = VaultEntry.passwordType,
  });

  final VaultEntry? existing;
  final String type;

  static Route<void> route({
    VaultEntry? existing,
    String type = VaultEntry.passwordType,
  }) {
    return PageRouteBuilder<void>(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) {
        return EntryEditor(existing: existing, type: type);
      },
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
  State<EntryEditor> createState() => _EntryEditorState();
}

class _EntryEditorState extends State<EntryEditor> {
  late String _type;
  late final TextEditingController _title;
  late final TextEditingController _username;
  late final TextEditingController _notes;
  late final TextEditingController _password;

  final List<TextEditingController> _words = <TextEditingController>[];
  double _wordCount = 5;
  bool _reveal = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final VaultEntry? existing = widget.existing;
    _type = existing?.type ?? widget.type;

    _title = TextEditingController(text: existing?.title ?? '');
    _username = TextEditingController(text: existing?.username ?? '');
    _notes = TextEditingController(text: existing?.notes ?? '');
    _password = TextEditingController(
      text: existing != null && !existing.isPassphrase ? existing.secret : '',
    );

    if (existing != null && existing.isPassphrase) {
      final List<String> words = existing.words;
      _wordCount = words.length.clamp(PasswordGenerator.minWords, PasswordGenerator.maxWords).toDouble();
      for (final String word in words) {
        _words.add(TextEditingController(text: word));
      }
    } else {
      _syncWords();
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _username.dispose();
    _notes.dispose();
    _password.dispose();
    for (final TextEditingController c in _words) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isPassphrase => _type == VaultEntry.passphraseType;

  void _syncWords() {
    final int target = _wordCount.round().clamp(
        PasswordGenerator.minWords, PasswordGenerator.maxWords);
    while (_words.length < target) {
      _words.add(TextEditingController());
    }
    while (_words.length > target) {
      _words.removeLast().dispose();
    }
  }

  void _generatePassword() {
    setState(() => _password.text = PasswordGenerator.password());
    HapticFeedback.selectionClick();
  }

  void _generatePassphrase() {
    final List<String> words = PasswordGenerator.passphrase(_wordCount.round());
    setState(() {
      for (final TextEditingController c in _words) {
        c.dispose();
      }
      _words
        ..clear()
        ..addAll(words.map((String w) => TextEditingController(text: w)));
    });
    HapticFeedback.selectionClick();
  }

  Future<void> _save() async {
    final String title = _title.text.trim();
    if (title.isEmpty) {
      showSnack(context, 'Give it a name first');
      return;
    }

    final String secret = _isPassphrase
        ? _words
            .map((TextEditingController c) => c.text.trim())
            .where((String w) => w.isNotEmpty)
            .join(' ')
        : _password.text.trim();

    if (secret.isEmpty) {
      showSnack(
        context,
        _isPassphrase
            ? 'Add at least one word'
            : 'Type or generate a password',
      );
      return;
    }

    setState(() => _saving = true);

    final VaultStore store = VaultStore.instance;
    bool ok;
    final VaultEntry? existing = widget.existing;
    if (existing != null) {
      existing
        ..title = title
        ..username = _username.text.trim()
        ..notes = _notes.text.trim()
        ..secret = secret
        ..type = _type
        ..updatedAt = DateTime.now().millisecondsSinceEpoch;
      ok = await store.updateEntry(existing);
    } else {
      ok = await store.addEntry(
        VaultEntry(
          title: title,
          username: _username.text.trim(),
          notes: _notes.text.trim(),
          secret: secret,
          type: _type,
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
    final Color soft = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;
    final bool isEditing = widget.existing != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(isEditing ? 'Edit entry' : 'New entry'),
        actions: <Widget>[
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              onPressed: _saving ? null : _save,
              child: Text(isEditing ? 'Save' : 'Add'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 40),
        children: <Widget>[
          const SectionLabel('Details'),
          TextField(
            controller: _title,
            textInputAction: TextInputAction.next,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'GitHub, bank, wifi...',
              prefixIcon: Icon(Icons.label_outline_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _username,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Username / email (optional)',
              prefixIcon: Icon(Icons.alternate_email_rounded, size: 20),
            ),
          ),
          const SizedBox(height: 12),
          if (!isEditing) ...<Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: LemonPill(
                    label: 'Password',
                    icon: Icons.key_rounded,
                    selected: !_isPassphrase,
                    onTap: () => setState(() => _type = VaultEntry.passwordType),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: LemonPill(
                    label: 'Passphrase',
                    icon: Icons.short_text_rounded,
                    selected: _isPassphrase,
                    color: LemonPalette.leaf,
                    onTap: () => setState(() => _type = VaultEntry.passphraseType),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
          ],
          if (!_isPassphrase) ...<Widget>[
            const SectionLabel('Password'),
            TextField(
              controller: _password,
              obscureText: !_reveal,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 15),
              decoration: InputDecoration(
                hintText: 'Type it or generate one',
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _reveal = !_reveal),
                  icon: Icon(
                    _reveal
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _generatePassword,
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: const Text('Generate 32-character password'),
            ),
          ] else ...<Widget>[
            SectionLabel('Passphrase · ${_wordCount.round()} words'),
            Row(
              children: <Widget>[
                Expanded(
                  child: Slider(
                    value: _wordCount,
                    min: PasswordGenerator.minWords.toDouble(),
                    max: PasswordGenerator.maxWords.toDouble(),
                    divisions: PasswordGenerator.maxWords - PasswordGenerator.minWords,
                    label: '${_wordCount.round()}',
                    onChanged: (double value) {
                      setState(() {
                        _wordCount = value;
                        _syncWords();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _generatePassphrase,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 44),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: const Text('Generate'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            for (int i = 0; i < _words.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 26,
                      child: Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: soft,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _words[i],
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          hintText: 'word ${i + 1}',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 14),
          const SectionLabel('Notes'),
          TextField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Anything worth remembering (optional)',
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(isEditing ? 'Save changes' : 'Add to vault'),
          ),
        ],
      ),
    );
  }
}
