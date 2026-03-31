import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/decide_screen.dart';

class DecideApp extends StatelessWidget {
  const DecideApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Decide For Us',
      theme: AppTheme.lightTheme,
      home: const DecideScreen(),
    );
  }
}