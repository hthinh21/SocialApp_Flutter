import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_project/components/cardpost.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class PostListScreen extends StatefulWidget {
  const PostListScreen({Key? key}) : super(key: key);
  @override
  _PostListScreenState createState() => _PostListScreenState();
}

class _PostListScreenState extends State<PostListScreen> {
  List<dynamic> defaultPost = [];
  List<dynamic> postIDs = [];
  List<dynamic> filterPost = [];
  bool loadingPost = false;
  bool loadNewest = false;
  bool loadOldest = false;
  bool loadFilter = false;
  String selectedItem = '';
  String selectedDate = '';

  @override
  void initState() {
    super.initState();
    fetchFollow();
  }

  Future<Map<String, dynamic>> fetchUserById(String id) async {
    final res = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/$id'));
    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return {};
  }

  Future<void> fetchFollow() async {
    setState(() => loadingPost = true);
    final prefs = await SharedPreferences.getInstance();
    final userID = prefs.getString('customerId');
    if (userID == null) {
      setState(() {
        loadingPost = false;
        postIDs = [];
      });
      return;
    }

    try {
      final resFollow = await http.get(Uri.parse('https://dhkptsocial.onrender.com/users/$userID'));
      final data = json.decode(resFollow.body);
      List followers = data['followings'];
      List postList = [];

      for (var follower in followers) {
        final resArticle = await http.get(Uri.parse('https://dhkptsocial.onrender.com/articles/${follower["_id"]}'));
        final articleData = json.decode(resArticle.body);

        for (var post in articleData['data']) {
          final user = await fetchUserById(post['userID']);
          post['username'] = user['username'] ?? 'Ẩn danh';
          post['avatar'] = user['avatar'];
          postList.add(post);
        }
      }

      setState(() {
        defaultPost = postList;
        postIDs = List.from(postList)..shuffle();
        loadingPost = false;
      });
    } catch (e) {
      print('Lỗi hoặc chưa theo dõi ai: $e');
      setState(() => loadingPost = false);
    }
  }

  List<dynamic> sortPostsByDate(List<dynamic> posts, {bool ascending = false}) {
    posts.sort((a, b) {
      DateTime dateA = DateTime.parse(a['publishDate']);
      DateTime dateB = DateTime.parse(b['publishDate']);
      return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
    });
    return posts;
  }

  void handleFilter(String date) {
    setState(() {
      selectedDate = date;
      selectedItem = '';
      loadNewest = false;
      loadOldest = false;
      loadFilter = true;
      filterPost = defaultPost.where((post) {
        if (post['publishDate'] == null) return false;
        String postDate = post['publishDate'].split("T")[0];
        return postDate == date;
      }).toList();
    });
  }

  Widget buildPostItem(dynamic post) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: PostCard(
        postID: post['_id'],
        author: post['userID'],
        description: post['description'] ?? '',
        post: post,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: 'Lọc theo ngày',
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    controller: TextEditingController(text: selectedDate),
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        String formatted = DateFormat('yyyy-MM-dd').format(picked);
                        handleFilter(formatted);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    setState(() {
                      selectedItem = value;
                      loadNewest = value == 'Đăng gần đây';
                      loadOldest = value == 'Đăng đã lâu';
                      loadFilter = false;
                      selectedDate = '';
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'Đăng gần đây', child: Text('Đăng gần đây')),
                    const PopupMenuItem(value: 'Đăng đã lâu', child: Text('Đăng đã lâu')),
                  ],
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Text(selectedItem.isEmpty ? 'Bộ lọc' : selectedItem),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
          Expanded(
            child: loadingPost
                ? const Center(child: CircularProgressIndicator())
                : loadNewest
                    ? ListView(children: sortPostsByDate(defaultPost).map(buildPostItem).toList())
                    : loadOldest
                        ? ListView(children: sortPostsByDate(defaultPost, ascending: true).map(buildPostItem).toList())
                        : loadFilter
                            ? filterPost.isEmpty
                                ? const Center(child: Text('Không có kết quả nào được tìm thấy'))
                                : ListView(children: filterPost.map(buildPostItem).toList())
                            : postIDs.isEmpty
                                ? const Center(
                                    child: Text(
                                      'Bạn chưa theo dõi người dùng nào cả',
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : ListView(children: postIDs.map(buildPostItem).toList()),
          )
        ],
      ),
    );
  }
}
