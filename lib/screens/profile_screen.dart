import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_project/components/cardpost.dart';
import 'package:mobile_project/screens/other_user_profile_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_project/utils/logout.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfilePage> {
  String? customerId;
  Map<String, dynamic>? user;
  List<dynamic> followers = [];
  List<dynamic> followings = [];
  List<dynamic> posts = [];

  int visiblePosts = 12;
  bool loadingMore = false;
  bool loadedAll = false;
  bool isInitialLoading = true;
  String activeTab = 'posts';

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => isInitialLoading = true);
    final prefs = await SharedPreferences.getInstance();
    customerId = prefs.getString('customerId');
    if (customerId != null) {
      await _fetchUser();
      await _fetchPosts();
    }
    setState(() => isInitialLoading = false);
  }

  Future<void> _fetchUser() async {
    try {
      final res = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/users/$customerId'),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          user = data;
          followers = data['followers'] ?? [];
          followings = data['followings'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Lỗi khi tải thông tin người dùng: $e');
    }
  }

  Future<void> _fetchPosts() async {
    try {
      final res = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/articles/$customerId'),
      );
      if (res.statusCode == 200) {
        final list = jsonDecode(res.body)['data'] as List;
        final temp = <Map<String, dynamic>>[];

        for (var art in list) {
          final imgRes = await http.get(
            Uri.parse('https://dhkptsocial.onrender.com/files/${art['_id']}'),
          );
          final imgList = jsonDecode(imgRes.body) as List;

          temp.add({
            'id': art['_id'],
            'userID': art['userID'],
            'description': art['description'] ?? '',
            'numberOfLike': art['numberOfLike'] ?? 0,
            'numberOfComment': art['numberOfComment'] ?? 0,
            'publishDate': art['publishDate'] ?? '',
            'image': imgList.isNotEmpty ? imgList[0]['_id'] : null,
            'likes': art['numberOfLike'],
            'comments': art['numberOfComment'],
          });
        }

        setState(() => posts = temp);
      }
    } catch (e) {
      debugPrint('Lỗi khi tải bài viết: $e');
    }
  }

  Future<void> _refreshProfile() async {
    await _fetchUser();
    await _fetchPosts();
    setState(() {
      visiblePosts = 12;
      loadedAll = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã làm mới trang cá nhân')));
  }

  void _loadMore() {
    if (loadingMore || loadedAll) return;

    setState(() => loadingMore = true);
    Future.delayed(const Duration(seconds: 1), () {
      final total = activeTab == 'posts' ? posts.length : 0;
      if (visiblePosts < total) {
        visiblePosts += 12;
      } else {
        loadedAll = true;
      }
      setState(() => loadingMore = false);
    });
  }

  String _formatNumber(int num) {
    if (num >= 1000000) return '${(num / 1000000).toStringAsFixed(1)} Tr';
    if (num >= 10000) return '${(num / 1000).floor()} N';
    return num.toString();
  }

  @override
  Widget build(BuildContext context) {
    if (isInitialLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Trang cá nhân',
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 196, 108, 211),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showLogoutDialog,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildProfileHeader(),
              const SizedBox(height: 12),
              _buildStatsRow(),
              const Divider(height: 32),
              _buildTabs(),
              _buildPostsGallery(),
              _buildLoadMoreSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 50,
          backgroundImage:
              user?['avatar'] == null
                  ? const AssetImage('assets/images/default.jpg')
                  : NetworkImage(
                        'https://dhkptsocial.onrender.com/files/download/${user!['avatar']}',
                      )
                      as ImageProvider,
        ),
        const SizedBox(height: 8),
        Text(
          user?['username'] ?? '',
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(user?['name'] ?? ''),
        Text(user?['description'] ?? ''),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Column(
          children: [Text(_formatNumber(posts.length)), const Text('Bài viết')],
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showUsersModal(context, 'Người theo dõi', followers),
          child: Column(
            children: [
              Text(_formatNumber(followers.length)),
              const Text('Người theo dõi'),
            ],
          ),
        ),
        const SizedBox(width: 16),
        InkWell(
          onTap: () => _showUsersModal(context, 'Đang theo dõi', followings),
          child: Column(
            children: [
              Text(_formatNumber(followings.length)),
              const Text('Đang theo dõi'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabButton('posts', 'BÀI VIẾT'),
        const SizedBox(width: 20),
        _tabButton('bookmarks', 'ĐÃ LƯU'),
      ],
    );
  }

  Widget _tabButton(String key, String label) {
    return InkWell(
      onTap: () {
        setState(() {
          activeTab = key;
          visiblePosts = 12;
          loadedAll = false;
        });
      },
      child: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: activeTab == key ? Colors.blue : Colors.grey,
        ),
      ),
    );
  }

  Widget _buildPostsGallery() {
    final dataList = activeTab == 'posts' ? posts : [];

    return Padding(
      padding: const EdgeInsets.all(8),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount:
            dataList.length < visiblePosts ? dataList.length : visiblePosts,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 2,
          mainAxisSpacing: 2,
        ),
        itemBuilder: (_, index) {
          final item = dataList[index];
          return GestureDetector(
            onTap: () => _openPostDetail(item),
            child: Stack(
              children: [
                Image.network(
                  'https://dhkptsocial.onrender.com/files/download/${item['image']}',
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Positioned.fill(
                  child: Container(
                    color: Colors.black26,
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _iconText(Icons.favorite, item['likes']),
                          const SizedBox(width: 8),
                          _iconText(Icons.comment, item['comments']),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadMoreSection() {
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: CircularProgressIndicator(),
      );
    } else if (!loadedAll) {
      return TextButton(
        onPressed: _loadMore,
        child: const Text('Tải thêm bài viết'),
      );
    } else {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Đã tải hết bài viết.'),
      );
    }
  }

  Widget _iconText(IconData icon, int count) {
    return Row(
      children: [
        Icon(icon, color: Colors.white, size: 18),
        const SizedBox(width: 4),
        Text(_formatNumber(count), style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  void _openPostDetail(Map<String, dynamic> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: const Text('Chi tiết bài viết'),
                backgroundColor: Colors.purple,
              ),
              body: Center(
                child: SingleChildScrollView(
                  child: PostCard(
                    postID: item['id'] ?? '',
                    author: item['userID'] ?? '',
                    description: item['description'] ?? '',
                    post: item,
                  ),
                ),
              ),
            ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Đăng xuất'),
            content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Hủy'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  await logout(context);
                },
                child: const Text(
                  'Đăng xuất',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }

  void _showUsersModal(BuildContext ctx, String title, List list) {
    showDialog(
      context: ctx,
      builder:
          (_) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: double.maxFinite,
              height: 300,
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final u = list[i];
                  return ListTile(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => OtherUserProfile(userId: u['_id']),
                          ),
                        ),
                    leading: CircleAvatar(
                      backgroundImage:
                          u['avatar'] == null
                              ? const AssetImage('assets/images/default.jpg')
                              : NetworkImage(
                                'https://dhkptsocial.onrender.com/files/download/${u['avatar']}',
                              ),
                    ),
                    title: Text(u['username'] ?? ''),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Đóng'),
              ),
            ],
          ),
    );
  }
}
