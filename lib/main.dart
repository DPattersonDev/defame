import 'package:flutter/material.dart';

import 'screens/home_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const DeFameApp());
}

class DeFameApp extends StatelessWidget {
  const DeFameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Removes the Flutter debug banner.
      debugShowCheckedModeBanner: false,

      // App name.
      title: 'De-Fame',

      // Light mode appearance.
      theme: AppTheme.lightTheme,

      // Dark mode appearance.
      darkTheme: AppTheme.darkTheme,

      // Automatically follows the device theme.
      themeMode: ThemeMode.system,

      // First screen displayed when De-Fame opens.
      home: HomeScreen(),
    );
  }
}