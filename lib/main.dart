import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() => runApp(const KalingaApp());

class KalingaApp extends StatelessWidget {
  const KalingaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kalinga DNWG',
      home: const SplashScreen(),
    );
  }
}