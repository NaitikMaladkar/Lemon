package com.lemon.app;

import android.os.Bundle;
import android.view.WindowManager;

import androidx.annotation.NonNull;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

/**
 * Android host for the Flutter app.
 *
 * Java only - the project intentionally contains no Kotlin source files.
 * Provides the "com.lemon.app/secure" channel that switches on FLAG_SECURE so
 * the app cannot be screenshotted or screen recorded.
 */
public class MainActivity extends FlutterActivity {

    private static final String CHANNEL = "com.lemon.app/secure";

    @Override
    public void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        applySecureFlag();
    }

    private void applySecureFlag() {
        getWindow().setFlags(
                WindowManager.LayoutParams.FLAG_SECURE,
                WindowManager.LayoutParams.FLAG_SECURE
        );
    }

    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
        super.configureFlutterEngine(flutterEngine);
        new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
                .setMethodCallHandler((call, result) -> {
                    if ("enable".equals(call.method)) {
                        applySecureFlag();
                        result.success(true);
                    } else {
                        result.notImplemented();
                    }
                });
    }
}
