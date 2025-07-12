import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_project/components/cardpost.dart';
import 'package:mobile_project/screens/other_user_profile_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<dynamic> notifyList = [];
  String? customerId;

  @override
  void initState() {
    super.initState();
    _fetchNotify();
  }

  Future<void> _fetchNotify() async {
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getString('customerId');
    if (customerId != null) {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/notifications/$customerId'),
      );      
      if (response.statusCode == 200) {
        setState(() {
          notifyList = json.decode(response.body).reversed.toList();
        });
      } else {
        print('Không có thông báo nào cả');
      }
    }
  }

  void _handleNotifyArticle(Map<String, dynamic> post) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            title: const Text('Chi tiết bài viết'),
            backgroundColor: Colors.purple,
          ),
          body: Center(
            child: SingleChildScrollView(
              child: PostCard(
                postID: post['_id'] ?? '',
                author: post['userID'] ?? '',
                description: post['description'] ?? '',
                post: post,
              ),
            ),
          ),
        ),
      ),
    );
  }

void _handleNotifyUser(String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtherUserProfile(userId: userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lọc thông báo: chỉ lấy thông báo actor khác user đang đăng nhập
    final filteredNotifyList = notifyList.where((notification) {
      final actor = notification['actor'];
      return actor != null && actor['_id'] != customerId;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 196, 108, 211),
      ),
      body: filteredNotifyList.isEmpty
          ? Center(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 196, 108, 211),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: const Text(
                  'Không có thông báo nào',
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: filteredNotifyList.length,
              itemBuilder: (context, index) {
                var notification = filteredNotifyList[index];
                final actor = notification['actor'];
                final avatar = actor['avatar'];
                final name = actor['name'] ?? '';
                final actionDetail = notification['actionDetail'] ?? '';
                final userId = actor['_id'];

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 196, 108, 211),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: InkWell(
                    onTap: () {
                      if(notification['actionDetail'].contains('theo dõi')) {  
                        _handleNotifyUser(userId);
                      } else {
                        _handleNotifyArticle(notification['article']);
                      }
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: (avatar != null && avatar.toString().isNotEmpty)
                              ? NetworkImage('https://dhkptsocial.onrender.com/files/download/${actor!['avatar']}')
                              : const AssetImage('assets/images/default.jpg') as ImageProvider,
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: '$name',
                                  style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                TextSpan(
                                  text: ' $actionDetail',
                                  style: const TextStyle(color: Colors.white, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
