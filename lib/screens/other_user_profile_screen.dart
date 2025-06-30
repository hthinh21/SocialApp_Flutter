import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_project/components/cardpost.dart';

class OtherUserProfile extends StatefulWidget {
  final String userId;

  const OtherUserProfile({super.key, required this.userId});

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  Map<String, dynamic>? user;
  List<dynamic> posts = [];
  bool loading = true;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserPosts();
    checkFollowing();
  }

  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customerId') ?? '';
  }

  Future<void> checkFollowing() async {
    final currentUserId = await getCurrentUserId();
    final res = await http.get(Uri.parse(
        'https://dhkptsocial.onrender.com/users/is-following?from=$currentUserId&to=${widget.userId}'));

    if (res.statusCode == 200) {
      final result = json.decode(res.body);
      setState(() {
        isFollowing = result['isFollowing'];
      });
    }
  }

  Future<void> toggleFollow() async {
    final currentUserId = await getCurrentUserId();
    final url = isFollowing
        ? 'https://dhkptsocial.onrender.com/users/unfollow'
        : 'https://dhkptsocial.onrender.com/users/follow';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'from': currentUserId, 'to': widget.userId}),
    );

    if (res.statusCode == 200 && res.statusCode == 201) {
      setState(() {
        isFollowing = !isFollowing;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi thao tác theo dõi')),
      );
    }
  }

  Future<void> fetchUserData() async {
    final url = 'https://dhkptsocial.onrender.com/users/${widget.userId}';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
        loading = false;
      });
    } else {
      setState(() {
        loading = false;
      });
    }
  }

  Future<void> fetchUserPosts() async {
    final response = await http.get(Uri.parse('https://dhkptsocial.onrender.com/articles/${widget.userId}'));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<dynamic> fetchedPosts = [];

      for (var post in data['data']) {
        final imageRes = await http.get(Uri.parse('https://dhkptsocial.onrender.com/files/${post['_id']}'));
        final images = json.decode(imageRes.body);
        post['image'] = images[0]['_id'];
        fetchedPosts.add(post);
      }

      setState(() {
        posts = fetchedPosts;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(user!['username'] ?? '')),
      body: Column(
        children: [
          const SizedBox(height: 10),
          CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage(
              'https://dhkptsocial.onrender.com/files/download/${user!['avatar']}',
            ),
          ),
          const SizedBox(height: 10),
          Text(user!['name'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(user!['description'] ?? '', style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: toggleFollow,
            style: ElevatedButton.styleFrom(
              backgroundColor: isFollowing ? Colors.grey : Colors.purple,
            ),
            child: Text(isFollowing ? 'Hủy theo dõi' : 'Theo dõi'),
          ),
          const SizedBox(height: 20),
          const Divider(),
          const Text('Bài viết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: posts.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemBuilder: (context, index) {
                final post = posts[index];
                return GestureDetector(
                  onTap: () {
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
                                author: post['userID'] is Map ? post['userID']['_id'] ?? '' : post['userID'] ?? '',
                                description: post['description'] ?? '',
                                post: post,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: Image.network(
                    'https://dhkptsocial.onrender.com/files/download/${post['image']}',
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
