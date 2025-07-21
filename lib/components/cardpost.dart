import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_project/screens/other_user_profile_screen.dart';
import 'package:mobile_project/screens/profile_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:intl/intl.dart';

class PostCard extends StatefulWidget {
  final String postID;
  final String author;
  final String description;
  final Map<String, dynamic> post;

  const PostCard({
    Key? key,
    required this.postID,
    required this.author,
    required this.description,
    required this.post,
  }) : super(key: key);

  @override
  _PostCardState createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  String currentUserId = '';
  String currentUserName ='';
  String author = '';
  String avaAuthor = '';
  String authorID = '';
  String username = '';
  List<dynamic> files = [];
  String comment = '';
  String descriptionPost = '';
  int fileLength = 0;
  int scrollPosition = 0;
  String postID = '';
  Map<String, dynamic> post = {};
  bool like = false;
  String likeID = '';
  List<dynamic> commentList = [];
  String reportDetails = '';
  String deleteCommentID = '';
  String reportCommentID = '';
  bool isHideDescription = false;


  // Controllers
  TextEditingController commentController = TextEditingController();
  TextEditingController reportController = TextEditingController();
  CarouselController carouselController = CarouselController();

  @override
  void initState() {
    super.initState();
    initializeData();
    fetchCurrentUser();
  }

  Future<void> initializeData() async {
    await fetchVideos(widget.postID);
    await fetchUser(widget.author); 
    setState(() {
      descriptionPost = widget.description;
      postID = widget.postID;
      post = widget.post;
    });
    await fetchLike();
    await fetchComment(widget.postID);
  }

  // API calls
  Future<void> fetchVideos(String postID) async {
    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/files/$postID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          files = data;
          fileLength = data.length;
        });
      }
    } catch (error) {
      print('Error fetching videos: $error');
    }
  }

  Future<void> fetchCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => currentUserId = prefs.getString('customerId') ?? '');
    setState(() => currentUserName = prefs.getString('customerName') ?? '');
  }

  Future<void> fetchUser(String userID) async {
    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/users/$userID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        setState(() {
          author = data['name'];
          avaAuthor = data['avatar'];
          username = data['username'];
          authorID = data['_id'];
        });       
      }
     
    } catch (error) {
      print('Error fetching user: $error');
    }
    
  }

  Future<void> fetchLike() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerID = prefs.getString('customerId') ?? '';
      
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/likes/$customerID/$postID'),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          like = data != null;
          likeID = data?['_id'] ?? '';
        });
      }
    } catch (error) {
      setState(() {
        like = false;
      });
    }
  }

  Future<void> fetchComment(String postID) async {
    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/comments/$postID'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          commentList = data['data'] ?? [];
        });
      }
    } catch (error) {
      print('Error fetching comments: $error');
    }
  }

  // Action handlers
  Future<void> handleLike() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerID = prefs.getString('customerId') ?? '';
      
      final likes = {
        'articleID': postID,
        'userID': customerID,
      };

      final response = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/likes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(likes),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Update post like count
        final articlePost = {'numberOfLike': post['numberOfLike'] + 1};
        await http.put(
          Uri.parse('https://dhkptsocial.onrender.com/articles/$postID'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(articlePost),
        );

        // Send notification
        final notification = {
          'user': authorID,
          'actor': customerID,
          'actionDetail': 'đã thích bài viết của bạn',
          'article': postID,
          'like': json.decode(response.body)['_id'],
        };
        
        await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(notification),
        );

        await fetchPost();
        await fetchLike();
      }
    } catch (error) {
      print('Error liking post: $error');
    }
  }

  Future<void> handleDislike() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customerID = prefs.getString('customerId') ?? '';
      
      final notify = {
        'user': authorID,
        'actor': customerID,
        'like': likeID,
      };

      await http.delete(
        Uri.parse('https://dhkptsocial.onrender.com/notifications'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(notify),
      );

      await http.delete(
        Uri.parse('https://dhkptsocial.onrender.com/likes/$likeID'),
      );

      final articlePost = {'numberOfLike': post['numberOfLike'] - 1};
      await http.put(
        Uri.parse('https://dhkptsocial.onrender.com/articles/$postID'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(articlePost),
      );

      await fetchPost();
      await fetchLike();
    } catch (error) {
      print('Error disliking post: $error');
    }
  }

  Future<void> fetchPost() async {
    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/articles/all/$postID'),
      );
      if (response.statusCode == 200) {
        setState(() {
          post = json.decode(response.body);
        });
      }
    } catch (error) {
      print('Error fetching post: $error');
    }
  }
  Future<void> handleDeletePost() async {
    try {
      final response = await http.delete(
        Uri.parse('https://dhkptsocial.onrender.com/articles/$postID'),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bài viết đã được xóa')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lỗi khi xóa bài viết')),
        );
      }
    } catch (error) {
      print('Error deleting post: $error');
    }
  }

  Future<void> handleReportPost() async {
  if (reportDetails.length > 200) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Mô tả báo cáo có độ dài bé hơn 200 ký tự')),
    );
    return;
  }

  try {
    // Kiểm tra đã báo cáo chưa
    final checkRes = await http.get(
      Uri.parse('https://dhkptsocial.onrender.com/reports/$currentUserId/$postID'),
    );
    if (checkRes.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bài đăng đã được báo cáo')),
      );
      Navigator.of(context).pop(); // Đóng dialog báo cáo nếu có
      return;
    }
  } catch (e) {
    // Nếu chưa báo cáo thì tiếp tục báo cáo
    final data = {
      'postID': postID,
      'userID': currentUserId,
      'reportDetails': reportDetails,
      'reportType': 'article',
    };
    final reportRes = await http.post(
      Uri.parse('https://dhkptsocial.onrender.com/reports/'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(data),
    );
    if (reportRes.statusCode == 200 || reportRes.statusCode == 201) {
      // Đổi trạng thái bài viết thành "reported"
      final newStatus = {'articleStatus': 'reported'};
      await http.put(
        Uri.parse('https://dhkptsocial.onrender.com/articles/$postID'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(newStatus),
      );
      Navigator.of(context).pop(); // Đóng dialog báo cáo nếu có
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Báo cáo bài đăng thành công')),
      );
    }
  }
}

  Future<void> handleComment() async {
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa nhập bình luận')),
      );
      return;
    }

    if (comment.length > 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Độ dài bình luận < 200 ký tự')),
      );
      return;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final customerID = prefs.getString('customerId') ?? '';
      
      final dataComment = {
        'articleID': postID,
        'userID': customerID,
        'commentDetail': comment,
      };

      final response = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/comments'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(dataComment),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bình luận thành công')),
        );
        
        setState(() {
          comment = '';
          commentController.clear();
        });

        final articlePost = {'numberOfComment': post['numberOfComment'] + 1};
        await http.put(
          Uri.parse('https://dhkptsocial.onrender.com/articles/$postID'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(articlePost),
        );

        final notification = {
          'user': authorID,
          'actor': customerID,
          'actionDetail': 'đã bình luận bài viết của bạn',
          'article': postID,
          'comment': json.decode(response.body)['_id'],
        };

        await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/notifications'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(notification),
        );

        await fetchPost();
        await fetchComment(postID);
      }
    } catch (error) {
      print('Error commenting: $error');
    }
    
  }

  String calculateTimeDifference(String? publishDate) {
  if (publishDate == null || publishDate.isEmpty) return 'Không xác định';
 try {
    final dateTime = DateTime.parse(publishDate);
    final formatter = DateFormat('dd/MM/yyyy - HH:mm');
    return formatter.format(dateTime);
  } catch (e) {
    return 'Không xác định';
  }
  // try {
  //   final currentDate = DateTime.now();
  //   final publish = DateTime.parse(publishDate);
  //   final difference = currentDate.difference(publish);

  //   if (difference.inDays > 0) {
  //     return '${difference.inDays} ngày trước';
  //   } else if (difference.inHours > 0) {
  //     return '${difference.inHours} giờ trước';
  //   } else if (difference.inMinutes > 0) {
  //     return '${difference.inMinutes} phút trước';
  //   } else {
  //     return 'Vừa đăng';
  //   }
  // } catch (e) {
  //   return 'Không xác định';
  // }
}


  void showCommentsModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.purple, Colors.pink],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: avaAuthor.isEmpty
                          ? const AssetImage('assets/images/default.jpg')
                          : NetworkImage(
                              'https://dhkptsocial.onrender.com/files/download/$avaAuthor',
                            ),
                      
                    ),
                    const SizedBox(width: 16),
                    Text(
                      author,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              // Comments list
              Expanded(
                child: ListView.builder(
                  itemCount: commentList.length,
                  itemBuilder: (context, index) {
                    final commentItem = commentList[index];
                    final isOwner = commentItem['userID']['_id'] == authorID;
                    
                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundImage: commentItem['userID']['avatar'] == null
                                ? const AssetImage('assets/images/default.jpg')
                                : NetworkImage(
                                    'https://dhkptsocial.onrender.com/files/download/${commentItem['userID']['avatar']}',
                                  ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                gradient: isOwner
                                    ? const LinearGradient(
                                        colors: [Colors.purple, Colors.pink],
                                      )
                                    : null,
                                color: isOwner ? null : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: isOwner
                                    ? null
                                    : Border.all(color: Colors.grey),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    commentItem['userID']['username'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isOwner ? Colors.white : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    commentItem['commentDetail'],
                                    style: TextStyle(
                                      color: isOwner ? Colors.white : Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              // Comment input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: commentController,
                        decoration: InputDecoration(
                          hintText: 'Nhập bình luận...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            comment = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: handleComment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        'Gửi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context)  {
    return Container( 
      width: 320,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final refs = await SharedPreferences.getInstance();
                    final currentUserId = refs.getString('customerId') ?? '';
                    (authorID == currentUserId)
                    // ignore: use_build_context_synchronously
                    ? Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(),
                      ),
                    )
                    // ignore: use_build_context_synchronously
                    : Navigator.of(context).push(
                        MaterialPageRoute(
                        builder: (context) => OtherUserProfile(userId: authorID),
                      ),
                    );
                  },
                  child: CircleAvatar(
                    backgroundImage: avaAuthor.isEmpty
                        ? const AssetImage('assets/images/default.jpg')
                        : NetworkImage(
                            'https://dhkptsocial.onrender.com/files/download/$avaAuthor',
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        '@$username',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        calculateTimeDifference(post['publishDate'] ?? ''),
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  color: Colors.black,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: authorID == currentUserId
                          ? const Text('Xóa bài viết',style:TextStyle(color: Colors.white))
                          : const Text('Báo cáo bài viết',style:TextStyle(color: Colors.white)),
                      onTap: () {
                        if(authorID == currentUserId){
                          showDialog(context: context, builder: (context) {
                            return AlertDialog(
                              title: const Text('Xóa bài viết'),
                              content: const Text('Bạn có chắc chắn muốn xóa bài viết này không?'),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                  child: const Text('Hủy'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    handleDeletePost();
                                  },
                                  child: const Text('Xóa'),
                                ),
                              ],
                            );
                          });
                        } else{
                          Future.delayed(Duration.zero, () {
            showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Báo cáo', style: TextStyle(fontWeight: FontWeight.bold,color: Colors.red,fontSize: 25),textAlign: TextAlign.center),
                  // title: const Text("UserId của bạn: $currentUserId"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("Báo cáo bài viết của: \n$author",style:const TextStyle(fontWeight: FontWeight.bold,fontSize: 20),textAlign: TextAlign.center),  
                      const SizedBox(height: 16),
                      TextField(
                        controller: TextEditingController(
                          
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Nội dung báo cáo',
                          hintText: 'Nhập nội dung báo cáo...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) {
                          reportDetails = value;
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        reportDetails = '';
                      },
                      child: const Text('Hủy'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await handleReportPost();
                        Navigator.of(context).pop();
                        reportDetails = '';
                      },
                      child: const Text('Lưu báo cáo'),
                    ),
                  ],
                );
              },
            );
          });
                        }

                      }
                    ),
                  ],
                ),
              ],
            ),
          ),       
          // Media carousel
          if (files.isNotEmpty)
            SizedBox(
              height: 250,
              child: CarouselSlider.builder(
                itemCount: files.length,
                options: CarouselOptions(
                  height: 250,
                  viewportFraction: 1.0,
                  enableInfiniteScroll: files.length > 1,
                  onPageChanged: (index, reason) {
                    setState(() {
                      scrollPosition = index;
                    });
                  },
                ),
                itemBuilder: (context, index, realIndex) {
                  final file = files[index];
                  final isVideo = file['filename'].contains('.mp4');
                  
                  return Container(
                    width: double.infinity,
                    child: isVideo
                        ? VideoPlayerWidget(
                            videoUrl: 'https://dhkptsocial.onrender.com/files/download/${file['_id']}',
                          )
                        : Image.network(
                            'https://dhkptsocial.onrender.com/files/download/${file['_id']}',
                            fit: BoxFit.contain,
                          ),
                  );
                },
              ),
            ),

          // Dots indicator
          if (files.length > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: files.asMap().entries.map((entry) {
                  return Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: scrollPosition == entry.key
                          ? Colors.white
                          : Colors.grey,
                    ),
                  );
                }).toList(),
              ),
            ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: like ? handleDislike : handleLike,
                  child: Icon(
                    like ? Icons.favorite : Icons.favorite_border,
                    color: like ? Colors.red : Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: showCommentsModal,
                  child: const Icon(
                    Icons.comment_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Like count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              '${post['numberOfLike'] ?? 0} thích',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Description
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$author ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: descriptionPost.length > 50 && !isHideDescription
                            ? '${descriptionPost.substring(0, 50)}...'
                            : descriptionPost,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                if (descriptionPost.length > 50)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        isHideDescription = !isHideDescription;
                      });
                    },
                    child: Text(
                      isHideDescription ? 'Ẩn bớt' : 'Xem thêm',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: showCommentsModal,
                  child: Text(
                    'Xem tất cả ${post['numberOfComment'] ?? 0} bình luận',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Comment input
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: commentController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Nhập bình luận...',
                      hintStyle: const TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      filled: true,
                      fillColor: Colors.grey[800],
                    ),
                    onChanged: (value) {
                      setState(() {
                        comment = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: handleComment,
                  child: const Text(
                    'Bình luận',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    commentController.dispose();
    reportController.dispose();
    super.dispose();
  }
}

// Video player widget
class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;

  const VideoPlayerWidget({Key? key, required this.videoUrl}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((_) {
      setState(() {
        _isInitialized = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isInitialized
        ? AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          )
        : const Center(
            child: CircularProgressIndicator(),
          );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}