import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
  final response = await http.get(
    Uri.parse('https://dhkptsocial.onrender.com/users'),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    setState(() {
      users = jsonResponse['data'];  
    });
  } else {
    print("Lỗi khi gọi API: ${response.statusCode}");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách người dùng')),
      
      body: ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          
          return ListTile(
            title: Text(user['name']),
            subtitle: Text(user['_id']),
          );
        },
      ),
    );
  }
}
