import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class ChatDetailPage extends StatefulWidget {
  final dynamic contact;
  final String currentUserId;

  const ChatDetailPage({
    super.key,
    required this.contact,
    required this.currentUserId,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final String baseUrl = 'https://dhkptsocial.onrender.com';
  final TextEditingController controller = TextEditingController();
  final ScrollController scrollController = ScrollController();
  late IO.Socket socket;
  List<dynamic> messages = [];

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchMessages();
  }

  void initSocket() {
    socket = IO.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
      'reconnection': true,
    });

    socket.onConnect((_) => print("Socket connected"));

    socket.on('newMessage', (msg) {
      final content = msg['content']?.toString().trim();
      if (content == null || content.isEmpty) return;

      if ((msg['sender'] == widget.currentUserId &&
              msg['receiver'] == widget.contact['_id']) ||
          (msg['receiver'] == widget.currentUserId &&
              msg['sender'] == widget.contact['_id'])) {
        setState(() {
          messages.add(msg);
        });
        scrollToBottom();
      }
    });
  }

  Future<void> fetchMessages() async {
  final id = widget.contact['_id'];

  final res1 = await http.get(Uri.parse("$baseUrl/messages/${widget.currentUserId}/$id"));
  final res2 = await http.get(Uri.parse("$baseUrl/messages/$id/${widget.currentUserId}"));

  if (res1.statusCode == 200 && res2.statusCode == 200) {
    final combined = [
      ...jsonDecode(res1.body),
      ...jsonDecode(res2.body)
    ].where((msg) =>
      (msg['sender'] == widget.currentUserId && msg['receiver'] == widget.contact['_id']) ||
      (msg['receiver'] == widget.currentUserId && msg['sender'] == widget.contact['_id'])
    ).toList();

    //sap xep thoi gian
    combined.sort((a, b) => DateTime.parse(a['timestamp']).compareTo(DateTime.parse(b['timestamp'])));

    setState(() => messages = combined);
    scrollToBottom();  
  }
}


  void scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.jumpTo(scrollController.position.maxScrollExtent);
      }
    });
  }

  void sendMessage() async {
    final content = controller.text.trim();
    if (content.isEmpty) return;

    final msg = {
      'sender': widget.currentUserId,
      'receiver': widget.contact['_id'],
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await http.post(
      Uri.parse("$baseUrl/messages"),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(msg),
    );

    socket.emit('sendMessage', msg);
    setState(() {
    messages.add(msg);
  });
    scrollToBottom();
  
    controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final hasAvatar = widget.contact['avatar'] != null &&
        widget.contact['avatar'].toString().isNotEmpty;
    final contactName = widget.contact['name'] ?? 'Không rõ';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60), // chiều cao mới
        child: AppBar(
          backgroundColor: const Color.fromRGBO(123, 31, 162, 1),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
              size: 35, // tùy chỉnh size
            ),
            onPressed: () => Navigator.pop(context),
          ),
          leadingWidth: 40,
          title: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: hasAvatar
                    ? NetworkImage(
                        "$baseUrl/files/download/${widget.contact['avatar']}")
                    : const AssetImage("assets/images/default.jpg") as ImageProvider,
              ),
              const SizedBox(width: 12),
              Text(
                contactName,
                style: const TextStyle(fontSize: 20,color: Colors.white,fontWeight: FontWeight.bold), // tăng size chữ nếu cần
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: scrollController,
              itemCount: messages.length,
              itemBuilder: (_, index) {
                final msg = messages[index];
                final content = msg['content']?.toString().trim();
                if (content == null || content.isEmpty) {
                  return const SizedBox.shrink(); // bỏ qua tin nhắn rỗng
                }

                final isMe = msg['sender'] == widget.currentUserId;
                return Align(
                  alignment:
                      isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color.fromRGBO(123, 31, 162, 1) : Colors.grey.shade300, // nền khác cho contact
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          content,
                          style: TextStyle(
                            fontSize: 18,
                            color: isMe ? Colors.white : Colors.black, // màu chữ khác cho contact
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          msg['timestamp'] != null
                              ? (() {
                                  final dt = DateTime.tryParse(msg['timestamp']);
                                  if (dt != null) {
                                    final local = dt.toLocal();
                                    final hour = local.hour.toString().padLeft(2, '0');
                                    final minute = local.minute.toString().padLeft(2, '0');
                                    return '$hour:$minute';
                                  }
                                  return '';
                                })()
                              : '',
                          style: TextStyle(
                            color: isMe ? Colors.white70 : Colors.black54, // màu giờ khác cho contact
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
            color: const Color.fromRGBO(123, 31, 162, 1),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: controller,
                    onSubmitted: (_) => sendMessage(),
                    style: const TextStyle(color: Colors.black, fontFamily: 'Arial'),
                    decoration: InputDecoration(
                      hintText: "Nhập tin nhắn...",
                      hintStyle: const TextStyle(color:Color(0xFF5A5A5A)),
                      filled: true,
                      fillColor: const Color(0xFFF0F4FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding:
                          const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: sendMessage,
                  icon: const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
