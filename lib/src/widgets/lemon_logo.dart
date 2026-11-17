import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The half-lemon brand mark. Uses the bundled asset and falls back to a
/// painted lemon if the image is ever missing.
class LemonLogo extends StatelessWidget {
  const LemonLogo({super.key, this.size = 64, this.showLeaf = true});

  final double size;
  final bool showLeaf;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        'assets/logo.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (BuildContext context, Object error, StackTrace? stack) =>
            CustomPaint(painter: _PaintedLemon(showLeaf: showLeaf)),
      ),
    );
  }
}

class _PaintedLemon extends CustomPainter {
  _PaintedLemon({required this.showLeaf});

  final bool showLeaf;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 2;

    canvas.drawCircle(center, radius, Paint()..color = LemonPalette.citrus);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.78),
      -math.pi / 2,
      math.pi,
      true,
      Paint()..color = LemonPalette.citrusSoft,
    );
    if (showLeaf) {
      canvas.save();
      canvas.translate(center.dx + radius * 0.45, center.dy - radius * 0.85);
      canvas.rotate(-0.5);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: radius * 0.7, height: radius * 0.3),
        Paint()..color = LemonPalette.leaf,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _PaintedLemon old) => old.showLeaf != showLeaf;
}

/// Round tinted plate used behind the logo.
class LogoPlate extends StatelessWidget {
  const LogoPlate({super.key, this.size = 96, this.child});

  final double size;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? <Color>[LemonPalette.nightSurfaceAlt, LemonPalette.nightSurface]
              : <Color>[Colors.white, LemonPalette.citrusSoft.withOpacity(0.55)],
        ),
        border: Border.all(
          color: (dark ? LemonPalette.nightLine : LemonPalette.citrus).withOpacity(0.35),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: LemonPalette.citrusDeep.withOpacity(dark ? 0.10 : 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Center(
        child: child ?? LemonLogo(size: size * 0.62),
      ),
    );
  }
}
