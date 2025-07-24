import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_project/components/cardpost.dart';
import 'package:mobile_project/screens/profile_screen.dart';
class OtherUserProfile extends StatefulWidget {
  final String userId;

  const OtherUserProfile({super.key, required this.userId});

  @override
  State<OtherUserProfile> createState() => _OtherUserProfileState();
}

class _OtherUserProfileState extends State<OtherUserProfile> {
  Map<String, dynamic>? user;
  List<dynamic> posts = [];
  List<dynamic> followers = [];
  List<dynamic> followings = [];
  bool loading = true;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchUserPosts();
  }

  Future<String> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('customerId') ?? '';
  }

  Future<void> toggleFollow() async {
    final currentUserId = await getCurrentUserId();
    final url = 'https://dhkptsocial.onrender.com/users/follow/${widget.userId}';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'loggedInUserId': currentUserId}),
    );

    if (res.statusCode == 200 ) {
      
      setState(() {
        isFollowing = !isFollowing;
      });    
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lỗi khi thao tác theo dõi')),
      );
    }
    await fetchUserData(); // Cập nhật lại dữ liệu người dùng sau khi theo dõi
  }

  Future<void> fetchUserData() async {
    final url = 'https://dhkptsocial.onrender.com/users/${widget.userId}';
    final response = await http.get(Uri.parse(url));
    final currentUserId = await getCurrentUserId();
    if (response.statusCode == 200) {
      setState(() {
        user = json.decode(response.body);
        followers = user?['followers'] ?? [];
        followings = user?['followings'] ?? [];
        isFollowing = followers.map((e) => e['_id']).contains(currentUserId);
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
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchUserData();
          await fetchUserPosts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 50,
                backgroundImage: user!['avatar'] == null
                    ? const AssetImage('assets/images/default.jpg')
                    : NetworkImage('https://dhkptsocial.onrender.com/files/download/${user!['avatar']}'),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.red : Colors.blue,
                ),
                child: Text(
                  isFollowing ? 'Hủy theo dõi' : 'Theo dõi',
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              Text(user!['username'] ?? '', style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(user!['name'] ?? ''),
              
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Column(children: [
                    Text(posts.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                    const Text('Bài viết'),
                  ]),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => _showUsersModal(context, 'Người theo dõi', followers),
                    child: Column(children: [
                      Text(followers.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Người theo dõi'),
                    ]),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () => _showUsersModal(context, 'Đang theo dõi', followings),
                    child: Column(children: [
                      Text(followings.length.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                      const Text('Đang theo dõi'),
                    ]),
                  ),
                ],
              ),
              const Divider(height: 32),
              const Text('Bài viết', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              Padding(
                padding: const EdgeInsets.all(8),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: posts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2),
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
                                title: const Text('Chi tiết bài viết',
                                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
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
        ),
      ),
    );
  }

  
  void _showUsersModal(BuildContext ctx, String title, List list) async {
    final prefs = await SharedPreferences.getInstance();
    final currentUserId = prefs.getString('customerId') ?? '';
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (_, i) {
              final u = list[i];
              return ListTile(
                onTap: u['_id'] == currentUserId
                    ? () => Navigator.push(ctx, MaterialPageRoute(builder: (context) => const ProfileScreen()))
                    : () => Navigator.push(
                        ctx,
                        MaterialPageRoute(
                          builder: (context) => OtherUserProfile(userId: u['_id']),
                        ),
                      ),               
                leading: 
                CircleAvatar(
                  backgroundImage: u['avatar'] == null
                      ? const AssetImage('assets/images/default.jpg')
                      : NetworkImage('https://dhkptsocial.onrender.com/files/download/${u['avatar']}'),
                ),
                title: Text(u['username'] ?? ''),
              );
            },
          ),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Đóng'))],
      ));
  }
}
