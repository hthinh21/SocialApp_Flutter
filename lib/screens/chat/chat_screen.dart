import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class MessagesPage extends StatefulWidget {
  const MessagesPage({super.key});

  @override
  State<MessagesPage> createState() => _MessagesPageState();
}

class _MessagesPageState extends State<MessagesPage> {
  final String currentUserId = '664ef40129b89a1a239fxxxx'; // ID giả lập
  final String baseUrl = 'https://dhkptsocial.onrender.com'; // 🔥 CHỈ CẦN SỬA Ở ĐÂY

  late IO.Socket socket;
  List<dynamic> contacts = [];
  dynamic selectedContact;
  List<dynamic> messages = [];
  Map<String, dynamic> lastMessages = {};
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    connectSocket();
    fetchContacts();
  }

  void connectSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
    });

    socket.onConnect((_) => print("Socket connected"));
    socket.onDisconnect((_) => print("Socket disconnected"));

    socket.on('newMessage', (msg) {
      final receiverId = selectedContact?['_id'];
      if ((msg['sender'] == currentUserId && msg['receiver'] == receiverId) ||
          (msg['receiver'] == currentUserId && msg['sender'] == receiverId)) {
        setState(() {
          messages.add(msg);
        });
        scrollToBottom();
      }
    });
  }

  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void fetchContacts() async {
    final res = await http.get(Uri.parse("$baseUrl/users"));
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body)['data'];
      final users = data.where((u) => u['_id'] != currentUserId).toList();
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

  void fetchMessages() async {
    if (selectedContact == null) return;
    final id = selectedContact['_id'];

    final res1 = await http.get(Uri.parse("$baseUrl/messages/$currentUserId/$id"));
    final res2 = await http.get(Uri.parse("$baseUrl/messages/$id/$currentUserId"));

    if (res1.statusCode == 200 && res2.statusCode == 200) {
      final combined = [...jsonDecode(res1.body), ...jsonDecode(res2.body)];
      combined.sort((a, b) =>
          DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));
      setState(() => messages = combined);
      scrollToBottom();
    }
  }

  void sendMessage() async {
    if (messageController.text.trim().isEmpty) return;

    final msg = {
      'sender': currentUserId,
      'receiver': selectedContact['_id'],
      'content': messageController.text,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await http.post(
      Uri.parse("$baseUrl/messages"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(msg),
    );

    socket.emit("sendMessage", msg);
    messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Bên trái: danh sách bạn bè
          Expanded(
            flex: 2,
            child: Container(
              color: Colors.black,
              child: ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final user = contacts[index];
                  return ListTile(
                    onTap: () {
                      setState(() {
                        selectedContact = user;
                        messages.clear();
                      });
                      fetchMessages();
                    },
                    leading: CircleAvatar(
                      backgroundImage: user['avatar'] != null
                          ? NetworkImage("$baseUrl/files/download/${user['avatar']}")
                          : const AssetImage("assets/image.png") as ImageProvider,
                    ),
                    title: Text(user['name'], style: const TextStyle(color: Colors.white)),
                    subtitle: Text(
                      lastMessages[user['_id']]?['content'] ?? 'No messages yet',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  );
                },
              ),
            ),
          ),

          // Bên phải: khung chat
          Expanded(
            flex: 3,
            child: Container(
              color: Colors.black,
              child: selectedContact == null
                  ? const Center(
                      child: Text("Chọn một cuộc trò chuyện để bắt đầu",
                          style: TextStyle(color: Colors.white70)))
                  : Column(
                      children: [
                        // Header
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                              border: Border(bottom: BorderSide(color: Colors.grey))),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: selectedContact['avatar'] != null
                                    ? NetworkImage("$baseUrl/files/download/${selectedContact['avatar']}")
                                    : const AssetImage("assets/image.png") as ImageProvider,
                              ),
                              const SizedBox(width: 12),
                              Text(selectedContact['name'],
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),

                        // Tin nhắn
                        Expanded(
                          child: ListView.builder(
                            controller: scrollController,
                            itemCount: messages.length,
                            itemBuilder: (_, index) {
                              final msg = messages[index];
                              final isMe = msg['sender'] == currentUserId;
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue : Colors.grey.shade800,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(msg['content'],
                                          style: const TextStyle(color: Colors.white)),
                                      const SizedBox(height: 4),
                                      Text(
                                        TimeOfDay.fromDateTime(
                                          DateTime.parse(msg['timestamp']),
                                        ).format(context),
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        // Ô nhập và nút gửi
                        Container(
                          padding: const EdgeInsets.all(8),
                          color: Colors.grey.shade900,
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: messageController,
                                  onSubmitted: (_) => sendMessage(),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: "Nhập tin nhắn...",
                                    hintStyle: const TextStyle(color: Colors.grey),
                                    filled: true,
                                    fillColor: Colors.grey.shade800,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(20),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: sendMessage,
                                icon: const Icon(Icons.send, color: Colors.blue),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
