import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'lemon_logo.dart';

/// Layout shared by the unlock and setup screens.
///
/// Everything scales with the available height and width, so the keypad and its
/// footer stay on screen on a small phone (and on a landscape tablet) instead
/// of overflowing. If the window is really too short to fit the content, it
/// scrolls rather than clipping.
class PinScaffold extends StatefulWidget {
  const PinScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.footer,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String? footer;

  @override
  State<PinScaffold> createState() => _PinScaffoldState();
}

class _PinScaffoldState extends State<PinScaffold>
    with SingleTickerProviderStateMixin {
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 4),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool dark = theme.brightness == Brightness.dark;
    final Color soft = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;
    final Size size = MediaQuery.sizeOf(context);
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    // How much room the keypad block needs: 4 rows plus dots and hint.
    // Below ~600 px of height we start shrinking the decorative parts first.
    final double compact = ((size.height - bottomInset) / 700).clamp(0.72, 1.0);
    final double logoSize = (88 * compact + size.width * 0.02)
        .clamp(48.0, 104.0)
        .toDouble();

    return Scaffold(
      body: Stack(
        children: <Widget>[
          Positioned(
            top: -120,
            right: -90,
            child: _Blob(
              size: 300,
              color: LemonPalette.citrus.withValues(alpha: dark ? 0.10 : 0.20),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -110,
            child: _Blob(
              size: 320,
              color: LemonPalette.leaf.withValues(alpha: 0.10),
            ),
          ),
          SafeArea(
            bottom: false,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool tight = constraints.maxHeight < 640;
                return SingleChildScrollView(
                  physics: tight
                      ? const ClampingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        tight ? 12 : 20,
                        16,
                        12 + bottomInset,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          if (!tight) ...<Widget>[
                            AnimatedBuilder(
                              animation: _float,
                              builder: (BuildContext context, Widget? child) {
                                final double t = _float.value;
                                return Transform.translate(
                                  offset: Offset(
                                    0,
                                    math.sin(t * math.pi * 2) * 5,
                                  ),
                                  child: child,
                                );
                              },
                              child: LogoPlate(size: logoSize),
                            ),
                            SizedBox(height: 14 * compact + 6),
                          ],
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              widget.title,
                              key: ValueKey<String>(widget.title),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontSize: (tight ? 21 : 24) * compact.clamp(0.9, 1.0),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 340),
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 220),
                              child: Text(
                                widget.subtitle,
                                key: ValueKey<String>(widget.subtitle),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: tight ? 12.5 : 13.5,
                                  height: 1.4,
                                  color: soft,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(height: tight ? 10 : 22 * compact + 4),
                          widget.child,
                          if (widget.footer != null) ...<Widget>[
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 320),
                              child: Text(
                                widget.footer!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  letterSpacing: 0.2,
                                  color: soft,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: <Color>[color, color.withValues(alpha: 0.0)],
        ),
      ),
    );
  }
}
