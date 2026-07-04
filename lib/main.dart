import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
}
 