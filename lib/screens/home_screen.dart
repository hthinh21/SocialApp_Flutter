import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<dynamic> users = [];

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  Future<void> fetchUsers() async {
  final response = await http.get(
    Uri.parse('http://192.168.16.2:1324/users'),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    final jsonResponse = json.decode(response.body);
    setState(() {
      users = jsonResponse['data'];  // lấy danh sách users ở đây
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
