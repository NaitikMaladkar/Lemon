import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme.dart';

/// The mini circular lemon that counts a TOTP window down.
///
/// The lemon is cut into one citrus slice per second. As time runs out the
/// slices are eaten away from the top, each one vanishing at its own second,
/// and the last one is gone exactly at [period] seconds - then the parent
/// grows a brand new lemon for the next window.
class LemonTimer extends StatelessWidget {
  const LemonTimer({
    super.key,
    required this.period,
    required this.progress,
    required this.seconds,
    this.size = 64,
  });

  final int period;
  final double progress;
  final int seconds;
  final double size;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LemonPainter(
          progress: progress,
          period: period,
          seconds: seconds,
          dark: dark,
          urgent: seconds <= 5,
        ),
      ),
    );
  }
}

class _LemonPainter extends CustomPainter {
  _LemonPainter({
    required this.progress,
    required this.period,
    required this.seconds,
    required this.dark,
    required this.urgent,
  });

  final double progress;
  final int period;
  final int seconds;
  final bool dark;
  final bool urgent;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = math.min(size.width, size.height) / 2 - 4;
    final double coreRadius = radius * 0.40;

    // soft plate behind the lemon
    canvas.drawCircle(
      center,
      radius,
      Paint()..color = (dark ? Colors.white : LemonPalette.citrus).withOpacity(0.07),
    );

    final int count = math.min(period <= 0 ? 30 : period, 30);
    final double sweepPer = (2 * math.pi) / count;
    final double boundary = (progress.clamp(0.0, 1.0)) * count;
    const double startAngle = -math.pi / 2;
    final double gap = count > 20 ? 0.030 : 0.045;

    final double midRadius = (radius + coreRadius) / 2;
    final Rect ring = Rect.fromCircle(center: center, radius: midRadius);
    final double stroke = radius - coreRadius;

    final Color base = urgent ? LemonPalette.danger : LemonPalette.citrus;
    final Color alt = urgent
        ? const Color(0xFFE4675A)
        : (dark ? LemonPalette.nightCitrus : LemonPalette.citrusDeep);

    for (int i = 0; i < count; i++) {
      final double from = math.max(i.toDouble(), boundary);
      final double to = i + 1.0;
      if (to <= from) continue;

      final Paint paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = i.isEven ? base : alt;

      canvas.drawArc(
        ring,
        startAngle + from * sweepPer + gap,
        (to - from) * sweepPer - gap * 2,
        false,
        paint,
      );
    }

    // rind
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..color = (urgent ? LemonPalette.danger : LemonPalette.citrusDeep)
            .withOpacity(0.35),
    );

    // pith + core holding the seconds
    canvas.drawCircle(
      center,
      coreRadius + 2,
      Paint()..color = (dark ? LemonPalette.nightSurface : Colors.white).withOpacity(0.92),
    );
    canvas.drawCircle(
      center,
      coreRadius,
      Paint()..color = (urgent ? LemonPalette.danger : LemonPalette.citrus)
          .withOpacity(dark ? 0.28 : 0.20),
    );

    // little leaf
    final Offset leafCenter = Offset(
      center.dx + radius * 0.52,
      center.dy - radius * 0.78,
    );
    canvas.save();
    canvas.translate(leafCenter.dx, leafCenter.dy);
    canvas.rotate(-0.55);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 0.46, height: radius * 0.20),
      Paint()..color = LemonPalette.leaf,
    );
    canvas.restore();

    // seconds
    final TextPainter text = TextPainter(
      text: TextSpan(
        text: '$seconds',
        style: TextStyle(
          fontSize: radius * 0.62,
          fontWeight: FontWeight.w800,
          color: urgent
              ? LemonPalette.danger
              : (dark ? LemonPalette.nightInk : LemonPalette.ink),
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset(center.dx - text.width / 2, center.dy - text.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _LemonPainter old) =>
      old.progress != progress ||
      old.seconds != seconds ||
      old.dark != dark ||
      old.urgent != urgent ||
      old.period != period;
}
