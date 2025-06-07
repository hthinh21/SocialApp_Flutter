import 'package:flutter/material.dart';
import 'package:mobile_project/screens/chat/chat_screen.dart';
import 'package:mobile_project/screens/search_screen.dart';
import 'package:mobile_project/widgets/defaultwidget.dart';

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
    var nameWidgets = "Home";
    switch (index) {
      case 0:
        nameWidgets = "Home";
        break;
      case 1:
        return const SearchPage();
       
      case 2:
        return const MessagesPage();
      case 3:
        nameWidgets = "Profile";
        break;
      default:
        nameWidgets = "None";
        break;
    }
    return DefaultWidget(title: nameWidgets);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Social App"),
        centerTitle: true,
        backgroundColor: const Color.fromARGB(255, 196, 108, 211),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              
            },
          ),
        ],
        
        elevation: 0, // Remove shadow
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // Rounded corners at the bottom
          ),
        ),
      ),
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