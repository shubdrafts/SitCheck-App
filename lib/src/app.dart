import 'package:flutter/material.dart';

import 'screens/common/splash_screen.dart';
import 'theme/app_theme.dart';

class SitCheckApp extends StatelessWidget {
  const SitCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SitCheck',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}