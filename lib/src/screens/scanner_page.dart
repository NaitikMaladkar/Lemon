import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../theme.dart';
import '../totp.dart';
import '../vault_store.dart';
import '../widgets/common.dart';

/// QR scanner. Only the framed square in the middle is analysed - everything
/// outside it is covered by a translucent theme-coloured mask.
class ScannerPage extends StatefulWidget {
  const ScannerPage({super.key});

  static Route<void> route() => PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (BuildContext context, Animation<double> a, Animation<double> b) =>
            const ScannerPage(),
        transitionsBuilder:
            (BuildContext context, Animation<double> a, Animation<double> b, Widget child) {
          return FadeTransition(opacity: a, child: child);
        },
      );

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage>
    with SingleTickerProviderStateMixin {
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
  );

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  )..forward();

  bool _handled = false;
  bool _torch = false;
  String? _feedback;

  @override
  void dispose() {
    _controller.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_handled) return;
    for (final Barcode barcode in capture.barcodes) {
      final String? raw = barcode.rawValue;
      if (raw == null) continue;
      final entry = Totp.parseOtpAuth(raw);
      if (entry == null) {
        setState(() => _feedback = 'That QR is not an authenticator code');
        return;
      }
      _handled = true;
      HapticFeedback.mediumImpact();
      final bool ok = await VaultStore.instance.addTotp(entry);
      if (!mounted) return;
      Navigator.of(context).pop();
      showSnack(
        context,
        ok ? 'Added ${entry.label}' : 'Could not save - vault is read only',
      );
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool cameraSupported =
        !kIsWeb && (Platform.isAndroid || Platform.isIOS);
    final bool dark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (cameraSupported)
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
              errorBuilder: (BuildContext context, MobileScannerException e,
                  Widget? child) {
                return _CameraMessage(
                  message: 'Camera unavailable',
                  detail: e.errorDetails?.message ?? 'Check camera permissions.',
                );
              },
            )
          else
            _CameraMessage(
              message: 'Scanning is a phone feature',
              detail: 'On desktop, add the code with its Base32 secret instead.',
            ),
          if (cameraSupported) const _ScanMask(),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _entrance,
              builder: (BuildContext context, Widget? child) {
                return Opacity(
                  opacity: _entrance.value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, (1 - _entrance.value) * 18),
                    child: child,
                  ),
                );
              },
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: <Widget>[
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white),
                              onPressed: () => Navigator.of(context).pop(),
                            ),
                          ),
                          const Spacer(),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.45),
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              tooltip: 'Torch',
                              icon: Icon(
                                _torch
                                    ? Icons.flashlight_on_rounded
                                    : Icons.flashlight_off_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () async {
                                await _controller.toggleTorch();
                                setState(() => _torch = !_torch);
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      margin: const EdgeInsets.only(bottom: 44),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Text(
                        _feedback ?? 'Hold the QR inside the grid',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _feedback == null
                              ? Colors.white
                              : LemonPalette.citrus,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (dark) const SizedBox.shrink(),
        ],
      ),
    );
  }
}

/// Translucent scrim with a clear square window + grid + lemon brackets.
class _ScanMask extends StatelessWidget {
  const _ScanMask();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double side =
            (constraints.biggest.shortestSide * 0.66).clamp(180.0, 320.0);
        final double left = (constraints.maxWidth - side) / 2;
        final double top = (constraints.maxHeight - side) / 2 - 30;

        return Stack(
          children: <Widget>[
            Positioned.fill(
              child: CustomPaint(
                painter: _MaskPainter(
                  window: Rect.fromLTWH(left, top, side, side),
                  radius: 26,
                ),
              ),
            ),
            Positioned(
              left: left,
              top: top,
              width: side,
              height: side,
              child: const _GridWindow(),
            ),
          ],
        );
      },
    );
  }
}

class _MaskPainter extends CustomPainter {
  _MaskPainter({required this.window, required this.radius});

  final Rect window;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(window, Radius.circular(radius)));

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xE6131208),
    );

    // lemon corner brackets
    final Paint bracket = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.4
      ..strokeCap = StrokeCap.round
      ..color = LemonPalette.citrus;

    const double len = 30;
    const double out = 3;
    final Rect r = window.inflate(out);

    void line(Offset a, Offset b) => canvas.drawLine(a, b, bracket);

    line(r.topLeft, r.topLeft + const Offset(len, 0));
    line(r.topLeft, r.topLeft + const Offset(0, len));
    line(r.topRight, r.topRight + const Offset(-len, 0));
    line(r.topRight, r.topRight + const Offset(0, len));
    line(r.bottomLeft, r.bottomLeft + const Offset(len, 0));
    line(r.bottomLeft, r.bottomLeft + const Offset(0, -len));
    line(r.bottomRight, r.bottomRight + const Offset(-len, 0));
    line(r.bottomRight, r.bottomRight + const Offset(0, -len));
  }

  @override
  bool shouldRepaint(covariant _MaskPainter old) =>
      old.window != window || old.radius != radius;
}

class _GridWindow extends StatefulWidget {
  const _GridWindow();

  @override
  State<_GridWindow> createState() => _GridWindowState();
}

class _GridWindowState extends State<_GridWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweep = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _sweep.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // 3x3 grid
          CustomPaint(painter: _GridPainter()),
          // moving scan line
          AnimatedBuilder(
            animation: _sweep,
            builder: (BuildContext context, Widget? child) {
              return Align(
                alignment: Alignment(0, _sweep.value * 2 - 1),
                child: child,
              );
            },
            child: Container(
              height: 2,
              margin: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    LemonPalette.citrus.withOpacity(0.0),
                    LemonPalette.citrus,
                    LemonPalette.citrus.withOpacity(0.0),
                  ],
                ),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: LemonPalette.citrus.withOpacity(0.55),
                    blurRadius: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9
      ..color = Colors.white.withOpacity(0.22);

    for (int i = 1; i < 3; i++) {
      final double x = size.width * i / 3;
      final double y = size.height * i / 3;
      canvas.drawLine(Offset(x, 8), Offset(x, size.height - 8), paint);
      canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CameraMessage extends StatelessWidget {
  const _CameraMessage({required this.message, required this.detail});

  final String message;
  final String detail;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF14130B),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.no_photography_outlined, size: 42, color: LemonPalette.citrus),
              const SizedBox(height: 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFFB9B7A0), fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
