import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'src/platform/secure_screen.dart';
import 'src/screens/root_gate.dart';
import 'src/theme.dart';
import 'src/vault_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await VaultStore.instance.init();
  await SecureScreen.enable();

  SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(const LemonApp());
}

class LemonApp extends StatelessWidget {
  const LemonApp({super.key});

  @override
  Widget build(BuildContext context) {
    final VaultStore store = VaultStore.instance;

    return ValueListenableBuilder<ThemeMode>(
      valueListenable: store.themeMode,
      builder: (BuildContext context, ThemeMode mode, Widget? child) {
        return MaterialApp(
          title: 'Lemon',
          debugShowCheckedModeBanner: false,
          theme: LemonTheme.light(),
          darkTheme: LemonTheme.dark(),
          themeMode: mode,
          home: const RootGate(),
          builder: (BuildContext context, Widget? child) {
            final MediaQueryData mq = MediaQuery.of(context);
            final TargetPlatform platform = Theme.of(context).platform;
            final bool desktop = platform != TargetPlatform.android &&
                platform != TargetPlatform.iOS;

            // Keep text from ballooning on desktop and phone alike.
            final Widget content = MediaQuery(
              data: mq.copyWith(
                textScaler: mq.textScaler.clamp(
                  minScaleFactor: 0.9,
                  maxScaleFactor: 1.2,
                ),
              ),
              child: child ?? const SizedBox.shrink(),
            );

            if (!desktop) return content;
            return ColoredBox(
              color: mode == ThemeMode.dark
                  ? const Color(0xFF0A0A06)
                  : const Color(0xFFF6EEDC),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: content,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
