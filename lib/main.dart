import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const DHKPTSocialApp());
}

class DHKPTSocialApp extends StatelessWidget {
  const DHKPTSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DHKPTSocial',
      theme: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const LoginScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
