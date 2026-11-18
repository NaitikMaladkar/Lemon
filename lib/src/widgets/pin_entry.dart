import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';

/// Shared 4-digit PIN entry: dots, keypad, busy state, shake on error.
///
/// [onComplete] returns `null` when everything went fine (the dots are cleared
/// silently) or an error message, in which case the dots shake and reset.
class PinEntry extends StatefulWidget {
  const PinEntry({
    super.key,
    required this.onComplete,
    this.length = 4,
    this.enabled = true,
    this.hint = 'Enter your 4-digit PIN',
  });

  final Future<String?> Function(String pin) onComplete;
  final int length;
  final bool enabled;

  /// Idle helper line under the dots.
  final String hint;

  @override
  State<PinEntry> createState() => _PinEntryState();
}

class _PinEntryState extends State<PinEntry> with TickerProviderStateMixin {
  final List<int> _digits = <int>[];
  bool _busy = false;
  String? _error;
  late final AnimationController _shake = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _shake.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _locked => _busy || !widget.enabled;

  void _press(int digit) {
    if (_locked || _digits.length >= widget.length) return;
    HapticFeedback.selectionClick();
    setState(() {
      _digits.add(digit);
      _error = null;
    });
    if (_digits.length == widget.length) {
      _submit();
    }
  }

  void _backspace() {
    if (_locked) return;
    if (_digits.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() => _digits.removeLast());
  }

  Future<void> _submit() async {
    final String pin = _digits.join();
    setState(() => _busy = true);
    String? error;
    try {
      error = await widget.onComplete(pin);
    } catch (_) {
      error = 'Something went wrong. Try again.';
    }
    if (!mounted) return;
    if (error == null) {
      setState(() {
        _busy = false;
        _digits.clear();
        _error = null;
      });
      return;
    }
    HapticFeedback.heavyImpact();
    setState(() {
      _busy = false;
      _digits.clear();
      _error = error;
    });
    _shake.forward(from: 0);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      _backspace();
      return KeyEventResult.handled;
    }
    final String label = event.logicalKey.keyLabel;
    if (label.length == 1) {
      final int code = label.codeUnitAt(0);
      if (code >= 48 && code <= 57) {
        _press(code - 48);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color soft = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;

    // Size the keypad from the space that is actually available: three keys
    // per row, four rows, plus dots and the hint line. On a short screen the
    // keys shrink instead of pushing the bottom row off the display.
    final Size screen = MediaQuery.sizeOf(context);
    final double usableH =
        MediaQuery.sizeOf(context).height - MediaQuery.viewPaddingOf(context).vertical;
    // 4 rows (~0.86 * key) + dots + hint + paddings, as a rough budget.
    final double fromHeight = (usableH - 210) / 4.2;
    // 3 keys + 6 * 5 px horizontal padding per key, and 32 px of page margin.
    final double fromWidth = (screen.width - 32 - 30) / 3.0;
    final double keyH = (fromHeight < fromWidth ? fromHeight : fromWidth)
        .clamp(46.0, 68.0)
        .toDouble();
    // Never wider than a third of the padded row, whatever the height allows.
    final double keyW = (keyH * 1.32)
        .clamp(56.0, 94.0)
        .clamp(0.0, (screen.width - 32 - 30) / 3.0)
        .toDouble();

    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: GestureDetector(
        onTap: () => _focus.requestFocus(),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            AnimatedBuilder(
              animation: _shake,
              builder: (BuildContext context, Widget? child) {
                final double t = _shake.value;
                final double dx = (t == 0 || t == 1)
                    ? 0
                    : 14 * (1 - t) * _wave(t * 3.2);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: _Dots(
                length: widget.length,
                filled: _digits.length,
                error: _error != null,
              ),
            ),
            SizedBox(
              height: keyH < 56 ? 38 : 44,
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _busy
                      ? SizedBox(
                          key: const ValueKey<String>('busy'),
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: LemonPalette.citrus,
                          ),
                        )
                      : _error != null
                          ? Text(
                              _error!,
                              key: const ValueKey<String>('error'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: LemonPalette.danger,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            )
                          : Text(
                              widget.hint,
                              key: const ValueKey<String>('hint'),
                              textAlign: TextAlign.center,
                              style: TextStyle(color: soft, fontSize: 13),
                            ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            _Keypad(
              enabled: widget.enabled && !_busy,
              onDigit: _press,
              onBackspace: _backspace,
              keyWidth: keyW,
              keyHeight: keyH,
            ),
          ],
        ),
      ),
    );
  }

  double _wave(double x) {
    final double v = x - (x.floorToDouble());
    return (v * 2 - 1).clamp(-1.0, 1.0);
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.filled, required this.error});

  final int length;
  final int filled;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color border = error
        ? LemonPalette.danger
        : (dark ? LemonPalette.nightLine : LemonPalette.line);
    final Color active = error ? LemonPalette.danger : LemonPalette.citrus;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(length, (int index) {
        final bool on = index < filled;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutBack,
            width: on ? 20 : 16,
            height: on ? 20 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: on ? active : Colors.transparent,
              border: Border.all(color: on ? active : border, width: 2),
              boxShadow: on
                  ? <BoxShadow>[
                      BoxShadow(
                        color: active.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        );
      }),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    required this.enabled,
    required this.keyWidth,
    required this.keyHeight,
  });

  final ValueChanged<int> onDigit;
  final VoidCallback onBackspace;
  final bool enabled;
  final double keyWidth;
  final double keyHeight;

  @override
  Widget build(BuildContext context) {
    const List<List<String>> rows = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
      <String>['', '0', 'del'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        for (final List<String> row in rows)
          Padding(
            padding: EdgeInsets.symmetric(vertical: keyHeight < 58 ? 3 : 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: row.map((String value) {
                if (value.isEmpty) {
                  return SizedBox(width: keyWidth, height: keyHeight);
                }
                if (value == 'del') {
                  return _KeyButton(
                    width: keyWidth,
                    height: keyHeight,
                    enabled: enabled,
                    onTap: onBackspace,
                    child: Icon(
                      Icons.backspace_outlined,
                      size: keyHeight * 0.34,
                    ),
                  );
                }
                return _KeyButton(
                  width: keyWidth,
                  height: keyHeight,
                  enabled: enabled,
                  onTap: () => onDigit(int.parse(value)),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: keyHeight * 0.40,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _KeyButton extends StatefulWidget {
  const _KeyButton({
    required this.child,
    required this.onTap,
    required this.enabled,
    required this.width,
    required this.height,
  });

  final Widget child;
  final VoidCallback onTap;
  final bool enabled;
  final double width;
  final double height;

  @override
  State<_KeyButton> createState() => _KeyButtonState();
}

class _KeyButtonState extends State<_KeyButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color base = dark ? LemonPalette.nightSurface : Colors.white;
    final Color line = dark ? LemonPalette.nightLine : LemonPalette.line;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: GestureDetector(
        onTapDown: widget.enabled ? (_) => setState(() => _down = true) : null,
        onTapCancel: () => setState(() => _down = false),
        onTapUp: widget.enabled
            ? (_) {
                setState(() => _down = false);
                widget.onTap();
              }
            : null,
        child: AnimatedScale(
          scale: _down ? 0.92 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: widget.width,
            height: widget.height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _down
                  ? LemonPalette.citrus.withValues(alpha: dark ? 0.30 : 0.20)
                  : base,
              borderRadius: BorderRadius.circular(widget.height * 0.33),
              border: Border.all(color: _down ? LemonPalette.citrus : line),
              boxShadow: _down
                  ? null
                  : <BoxShadow>[
                      BoxShadow(
                        color: Colors.black.withValues(alpha: dark ? 0.18 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
            ),
            child: Opacity(
              opacity: widget.enabled ? 1 : 0.4,
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
