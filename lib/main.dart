import 'package:flutter/material.dart';
import 'package:mobile_project/screens/chat/chat_list_screen.dart';
import 'package:mobile_project/screens/home_screen.dart';
import 'package:mobile_project/screens/login_screen.dart';
import 'package:mobile_project/screens/profile_screen.dart';
import 'package:mobile_project/screens/search_screen.dart';
import 'package:mobile_project/screens/register.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mobile Project',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home:const LoginScreen(),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const Homepage(),
        '/chat': (context) => const ChatListPage(),
        '/search': (context) => const SearchPage(),
        '/profile': (context) => const ProfilePage(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
