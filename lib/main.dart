import 'package:flutter/material.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MapleCrustApp());
}

/// Root widget for the Maple Crust Bistro food ordering application.
class MapleCrustApp extends StatelessWidget {
  const MapleCrustApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Maple Crust Bistro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const HomeShell(),
    );
  }
}