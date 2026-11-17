import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';
import 'lemon_logo.dart';

/// Decorative background used by the unlock / setup screens: a couple of
/// soft citrus blobs plus a gently floating lemon.
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
  final Widget? footer;

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
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final Color soft = dark ? LemonPalette.nightInkSoft : LemonPalette.inkSoft;

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
              color: LemonPalette.leaf.withValues(alpha: dark ? 0.10 : 0.10),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: IntrinsicHeight(
                      child: Column(
                      children: <Widget>[
                        const Spacer(flex: 2),
                        AnimatedBuilder(
                          animation: _float,
                          builder: (BuildContext context, Widget? child) {
                            final double t = _float.value;
                            return Transform.translate(
                              offset: Offset(0, math.sin(t * math.pi * 2) * 6),
                              child: child,
                            );
                          },
                          child: const LogoPlate(size: 104),
                        ),
                        const SizedBox(height: 22),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Text(
                            widget.title,
                            key: ValueKey<String>(widget.title),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 36),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 220),
                            child: Text(
                              widget.subtitle,
                              key: ValueKey<String>(widget.subtitle),
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13.5, height: 1.45, color: soft),
                            ),
                          ),
                        ),
                        const Spacer(flex: 2),
                        widget.child,
                        const SizedBox(height: 14),
                        if (widget.footer != null) widget.footer!,
                        const SizedBox(height: 18),
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
