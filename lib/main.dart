import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app.dart';
import 'bridge/flux_bridge.dart';

// Provider to expose SharedPreferences pre-initialized on startup
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences has not been initialized');
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait only (industry-standard design constraint for phone file managers)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Enable dynamic font fetching at runtime so GoogleFonts can download the font if online,
  // or fall back gracefully to the system default font when offline (preventing fatal crash).
  GoogleFonts.config.allowRuntimeFetching = true;

  // Pre-initialize SharedPreferences for synchronous state access in providers
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize the bridge method channel handler to listen to events from Kotlin
  FluxBridge.initializeMethodCallHandler();

  // Trigger background initialization of the native indices asynchronously
  FluxBridge.initializeIndex();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const FluxApp(),
    ),
  );

  // Cold-start intent polling: check if app was opened via ACTION_VIEW.
  // FluxApp's onIntentFile listener will handle warm-start (onNewIntent).
  // Delay 500ms so GoRouter is fully initialized before navigating.
  Future.delayed(const Duration(milliseconds: 500), () async {
    final path = await FluxBridge.getIntentFilePath();
    if (path != null && path.isNotEmpty) {
      FluxBridge.deliverIntentPath(path);
    }
  });

  // Start real-time CPU & FPS performance logging loop
  _startPerformanceMonitor();
}

void _startPerformanceMonitor() {
  final List<Duration> frameTimestamps = [];
  final stopwatch = Stopwatch()..start();

  SchedulerBinding.instance.addPersistentFrameCallback((Duration timestamp) {
    frameTimestamps.add(stopwatch.elapsed);
  });

  Timer.periodic(const Duration(seconds: 1), (timer) async {
    final now = stopwatch.elapsed;
    // Retain only frames rendered during the last 1000 milliseconds
    frameTimestamps.removeWhere((t) => (now - t).inMilliseconds > 1000);
    final fps = frameTimestamps.length;

    final m = await FluxBridge.getPerformanceMetrics();
    final appCpu    = m['appCpu']?.toStringAsFixed(1) ?? '0.0';
    final systemCpu = m['systemCpu']?.toStringAsFixed(1) ?? '0.0';
    final batLvl    = m['batteryLevel'] ?? -1.0;
    final batTemp   = m['batteryTemp'] ?? -1.0;

    final batLvlStr  = batLvl >= 0 ? '${batLvl.toStringAsFixed(0)}%' : '--';
    final batTempStr = batTemp > 0 ? '${batTemp.toStringAsFixed(1)}°C' : '--';
    final heatTag    = (batTemp >= 43.0) ? ' 🔥HOT' : (batTemp >= 38.0) ? ' ⚠️WARM' : '';

    debugPrint(
      '[PERF] FPS: $fps | CPU(App): $appCpu% | CPU(Sys): $systemCpu%'
      ' | Bat: $batLvlStr @ $batTempStr$heatTag'
    );
  });
}