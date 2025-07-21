import 'dart:convert';
import 'dart:io';
import 'package:mobile_project/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _email = '';
  File? _avatarFile;
  String? _previewAvatarBase64;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId().then((_) => _fetchUserData());
  }

  Future<void> _loadUserId() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('customerId');
  }

  Future<void> _fetchUserData() async {
    if (_userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://dhkptsocial.onrender.com/users/$_userId'),
      );

      if (response.statusCode == 200) {
        final user = json.decode(response.body);
        setState(() {
          _usernameController.text = user['name'] ?? '';
          _email = user['email'] ?? '';
          _descriptionController.text = user['description'] ?? '';
          _previewAvatarBase64 = user['avatar'];
        });
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

  Future<void> _updateProfile() async {
    if (_avatarFile == null) {
      final data = {
        'name': _usernameController.text,
        'description': _descriptionController.text,
      };

      await http.put(
        Uri.parse('https://dhkptsocial.onrender.com/users/edit/$_userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
    } else {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dhkptsocial.onrender.com/files/upload/avatar'),
      );
      request.files.add(await http.MultipartFile.fromPath('avatar', _avatarFile!.path));
      final res = await request.send();

      final resData = await http.Response.fromStream(res);
      final body = json.decode(resData.body);
      final avatarId = body['file']['_id'];

      final data = {
        'name': _usernameController.text,
        'description': _descriptionController.text,
        'avatar': avatarId
      };

      await http.put(
        Uri.parse('https://dhkptsocial.onrender.com/users/edit/$_userId'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cập nhật thành công!')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatarFile = File(picked.path);
        _previewAvatarBase64 = null;
      });
    }
  }

  Widget _buildAvatar() {
    if (_avatarFile != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: FileImage(_avatarFile!),
      );
    } else if (_previewAvatarBase64 != null) {
      return CircleAvatar(
        radius: 60,
        backgroundImage: NetworkImage('https://dhkptsocial.onrender.com/files/${_previewAvatarBase64!}'),
      );
    } else {
      return const CircleAvatar(
        radius: 60,
        child: Icon(Icons.person, size: 60, color: Colors.white),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(123, 31, 162, 1), // purple
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(30),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),
                _buildAvatar(),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickAvatar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text("Chọn ảnh đại diện",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _usernameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Họ và tên'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: TextEditingController(text: _email),
                  enabled: false,
                  style: const TextStyle(color: Colors.grey),
                  decoration: _inputDecoration('Email'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration('Tiểu sử'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _updateProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple[600],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    "Lưu thay đổi",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.grey[850],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
