// chat_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_project/screens/chat/chat_detail_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  State<ChatListPage> createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final String baseUrl = 'https://dhkptsocial.onrender.com';
  late SharedPreferences prefs;
  late String currentUserId;

  List<dynamic> contacts = [];
  Map<String, dynamic> lastMessages = {};
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadCustomerId();
  }

Future<void> loadCustomerId() async {
  final prefs = await SharedPreferences.getInstance();
  final id = prefs.getString('customerId');

  if (id != null) {
    setState(() {
      currentUserId = id;
    });
    await fetchContacts(); 
  }
}
  Future<void> fetchContacts() async {
    final res = await http.get(Uri.parse("$baseUrl/users/mutual-follows?currentUserId=$currentUserId"));
    if (res.statusCode == 200) {
      final users = jsonDecode(res.body);
      setState(() => contacts = users);

      for (var contact in users) {
        final res2 = await http.get(Uri.parse(
          "$baseUrl/messages/lastMessage/$currentUserId/${contact['_id']}"));
        if (res2.statusCode == 200) {
          setState(() {
            lastMessages[contact['_id']] = jsonDecode(res2.body);
          });
        }
      }
    }
  }

  void openChat(BuildContext context, dynamic contact) async {
    setState(() => isLoading = true);
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatDetailPage(contact: contact, currentUserId: currentUserId!),
      ),
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Tin nhắn", style: TextStyle(fontSize: 25,fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromRGBO(123, 31, 162, 1),
        shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: contacts.length,
              itemBuilder: (context, index) {
                final contact = contacts[index];
                return Column(
                  children: [
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
                      onTap: () => openChat(context, contact),
                      leading: CircleAvatar(
                        radius: 30,
                        backgroundImage: contact['avatar'] != null && contact['avatar'].toString().isNotEmpty
                            ? NetworkImage("$baseUrl/files/download/${contact['avatar']}")
                            : const AssetImage('assets/images/default.jpg') as ImageProvider,
                      ),
                      title: Text(contact['name'], style: const TextStyle(color: Colors.black, fontSize: 20)),
                      subtitle: Text(
                        lastMessages[contact['_id']]?['content'] ?? 'No messages yet',
                        style: const TextStyle(color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Divider(
                      color: Colors.black,
                      thickness: 1,
                      indent: 25,
                      endIndent: 25,
                    ),
                  ],
                );
              },
            ),
            
            
    );
  }
}
