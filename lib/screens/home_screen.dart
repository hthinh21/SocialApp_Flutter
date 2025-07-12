import 'package:flutter/material.dart';
import 'package:mobile_project/screens/create_post_screen.dart';
import 'package:mobile_project/screens/notification_screen.dart';
import 'package:mobile_project/screens/post_list_screen.dart';
import 'package:mobile_project/screens/profile_screen.dart';
import 'package:mobile_project/screens/search_screen.dart';
import 'package:mobile_project/widgets/defaultwidget.dart';
import 'package:mobile_project/screens/chat/chat_list_screen.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _MainpageState();
}

class _MainpageState extends State<Homepage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _loadWidget(int index) {
    switch (index) {
      case 0:
        return const PostListScreen();
      case 1:
        return const SearchPage();
      case 2:
        return const CreatePostScreen();
      case 3:
        return const ChatListPage();
      case 4:
        return const ProfilePage();
      default:
        return DefaultWidget(title: "None");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 0
          ? AppBar(
              title: const Text("Trang chủ", style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
              centerTitle: true,
              backgroundColor: const Color.fromARGB(255, 196, 108, 211),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications),
                  color: Colors.white,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(
                      builder: (context) => NotificationScreen(),
                    )); 
                  },  
                ),
              ],
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
            )
          : null, 
      body: _loadWidget(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.post_add_sharp),
            label: 'Post',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.amber[800],
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
      ),
    );
  }
}