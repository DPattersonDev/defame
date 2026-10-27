import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Saved on this device; precise device location is never requested.
class AppPreferences {
  static final theme = ValueNotifier(ThemeMode.system);
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    theme.value = ThemeMode.values.firstWhere(
      (value) => value.name == prefs.getString('theme'),
      orElse: () => ThemeMode.system,
    );
  }

  static Future<void> setTheme(ThemeMode mode) async {
    await (await SharedPreferences.getInstance()).setString('theme', mode.name);
    theme.value = mode;
  }
}
