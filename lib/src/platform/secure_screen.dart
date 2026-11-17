import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks the Android host to switch on FLAG_SECURE so the app cannot be
/// screenshotted or screen recorded. The host is a tiny Java class - no Kotlin
/// anywhere in the project - and other platforms simply skip the call.
class SecureScreen {
  const SecureScreen._();

  static const MethodChannel _channel = MethodChannel('com.lemon.app/secure');

  static Future<void> enable() async {
    if (kIsWeb) return;
    if (!(Platform.isAndroid || Platform.isIOS)) return;
    try {
      await _channel.invokeMethod<void>('enable');
    } catch (_) {
      // the platform side is optional - never block startup on it
    }
  }
}
