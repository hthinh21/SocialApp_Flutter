import 'package:flutter/material.dart';
import 'package:mobile_project/screens/home_screen.dart';
import 'package:mobile_project/screens/login_screen.dart'; // import màn hình bạn vừa tạo

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(    
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const Homepage(),
    );
  }
}
