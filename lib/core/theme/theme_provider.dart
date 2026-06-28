import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart'; // import sharedPreferencesProvider

class ThemeNotifier extends Notifier<ThemeMode> {
  static const _themeKey = 'selected_theme_mode';

  @override
  ThemeMode build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final savedMode = prefs.getString(_themeKey);
    
    if (savedMode == 'light') return ThemeMode.light;
    if (savedMode == 'dark') return ThemeMode.dark;
    return ThemeMode.dark;
  }

  Future<void> toggleTheme(bool currentIsDark) async {
    final newMode = currentIsDark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, newMode == ThemeMode.light ? 'light' : 'dark');
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(() {
  return ThemeNotifier();
});
