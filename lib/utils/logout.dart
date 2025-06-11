import 'package:flutter/material.dart';
import 'package:mobile_project/screens/login_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> logout(BuildContext context) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove('customerId');
 
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (context) => const LoginScreen()),
  );
}