import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({Key? key}) : super(key: key);
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  List<PlatformFile> _mediaFiles = [];
  bool _isLoading = false;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
  }

  Future<void> _loadUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('customerId');
    });
  }

  Future<void> _pickMedia() async {
    var status = await Permission.storage.request();
  if (!status.isGranted) {
    _showSnackbar('Vui lòng cấp quyền truy cập bộ nhớ');
    return;
  }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'jpeg', 'mp4', 'mov', 'avi'],
      allowMultiple: true,
    );

    if (result != null) {
      setState(() {
        _mediaFiles = result.files;
      });
    }
  }

  void _removeMedia(int index) {
    setState(() {
      _mediaFiles.removeAt(index);
    });
  }

  Future<void> _uploadPost() async {
    final description = _descriptionController.text.trim();

    if (_userId == null) {
      _showSnackbar('Không tìm thấy thông tin người dùng');
      return;
    }
    if (description.isEmpty) {
      _showSnackbar('Nhập mô tả bài đăng');
      return;
    }
    if (description.length > 200) {
      _showSnackbar('Mô tả không quá 200 ký tự');
      return;
    }
    if (_mediaFiles.isEmpty) {
      _showSnackbar('Thêm hình ảnh hoặc video');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://dhkptsocial.onrender.com/articles'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'descriptionPost': description,
          'user': _userId,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final postId = jsonDecode(response.body)['_id'];

        for (final file in _mediaFiles) {
          final request = http.MultipartRequest(
            'POST',
            Uri.parse('https://dhkptsocial.onrender.com/files/upload'),
          );
          request.files.add(await http.MultipartFile.fromPath('file', file.path!));
          request.fields['postId'] = postId;
          final res = await request.send();
          if (res.statusCode != 200) {
            print('Upload thất bại: ${file.name}');
          }
        }

        _showSnackbar('Đăng bài thành công');
        _descriptionController.clear();
        setState(() => _mediaFiles.clear());
      } else {
        print("loi ${response.body}");
        _showSnackbar('Đăng bài thất bại');
      }
    } catch (e) {
      _showSnackbar('Lỗi mạng hoặc server');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _mediaFiles.length,
        itemBuilder: (context, index) {
          final file = _mediaFiles[index];
          final isVideo = file.extension?.toLowerCase().contains('mp4') == true;

          return Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: isVideo
                    ? Container(
                        width: 100,
                        color: Colors.black,
                        child: const Icon(Icons.videocam, color: Colors.white),
                      )
                    : Image.file(File(file.path!), width: 100, fit: BoxFit.cover),
              ),
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: () => _removeMedia(index),
                  child: const CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.red,
                    child: Icon(Icons.close, size: 16, color: Colors.white),
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tạo bài viết', style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold, color: Colors.white)),
              centerTitle: true,
              backgroundColor: const Color.fromRGBO(123, 31, 162, 1),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),    
              ),
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_mediaFiles.isNotEmpty) _buildMediaPreview(),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: _pickMedia,
                child: const Text('Thêm hình ảnh và video'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                maxLength: 200,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Mô tả bài viết',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _uploadPost,
                      child: const Text('Đăng tải'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
