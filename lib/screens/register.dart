import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dobController = TextEditingController();
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _repasswordController = TextEditingController();

  File? _avatar;
  bool _loading = false;

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _avatar = File(picked.path);
      });
    }
  }

  bool isOver18(String dob) {
    try {
      final birth = DateTime.parse(dob);
      final today = DateTime.now();
      int age = today.year - birth.year;
      if (today.month < birth.month ||
          (today.month == birth.month && today.day < birth.day)) {
        age--;
      }
      return age >= 18;
    } catch (_) {
      return false;
    }
  }

  bool isValidText(String text) {
    final lengthCheck = text.length >= 9 && text.length <= 20;
    final upperCaseCheck = RegExp(r'[A-Z]').hasMatch(text);
    final lowerCaseCheck = RegExp(r'[a-z]').hasMatch(text);
    final numberCheck = RegExp(r'[0-9]').hasMatch(text);
    final specialCharCheck = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
    return lengthCheck && upperCaseCheck && lowerCaseCheck && numberCheck && specialCharCheck;
  }

  bool isNotUsername(String username) {
    final lengthCheck = username.length < 9 || username.length > 20;
    final specialCharCheck = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(username);
    final numberCheck = RegExp(r'[0-9]').hasMatch(username[0]);
    return lengthCheck || specialCharCheck || numberCheck;
  }

  Future<void> _register() async {
    if (_avatar == null) {
      _showSnackbar('Vui lòng thêm ảnh đại diện');
      return;
    }
    if (_nameController.text.isEmpty) {
      _showSnackbar('Thiếu tên người dùng');
      return;
    }
    if (_nameController.text.length < 8 || _nameController.text.length > 20) {
      _showSnackbar('Tên người dùng phải có độ dài từ 8 đến 20 ký tự');
      return;
    }
    if (_dobController.text.isEmpty) {
      _showSnackbar('Thiếu ngày sinh');
      return;
    }
    if (!isOver18(_dobController.text)) {
      _showSnackbar('Người dùng đăng ký phải có độ tuổi từ 18 tuổi trở lên');
      return;
    }
    if (_emailController.text.isEmpty) {
      _showSnackbar('Thiếu email');
      return;
    }
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(_emailController.text)) {
      _showSnackbar('Email sai định dạng');
      return;
    }
    if (_usernameController.text.isEmpty) {
      _showSnackbar('Thiếu tên đăng nhập');
      return;
    }
    if (isNotUsername(_usernameController.text)) {
      _showSnackbar('Tên đăng nhập không có ký tự đặc biệt và có độ dài lớn hơn 8, bé hơn 20 ký tự');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnackbar('Thiếu mật khẩu');
      return;
    }
    if (!isValidText(_passwordController.text)) {
      _showSnackbar('Mật khẩu phải gồm chữ hoa, chữ thường, số, ký tự đặc biệt và có độ dài lớn hơn 8, bé hơn 20 ký tự');
      return;
    }
    if (_passwordController.text != _repasswordController.text) {
      _showSnackbar('Mật khẩu nhập lại không trùng khớp');
      return;
    }

    setState(() => _loading = true);

    try {
      // Upload avatar
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://dhkptsocial.onrender.com/files/upload/avatar'),
      );
      request.files.add(await http.MultipartFile.fromPath('avatar', _avatar!.path));
      var response = await request.send();
      if (response.statusCode == 200) {
        var respStr = await response.stream.bytesToString();
        var respJson = json.decode(respStr);
        var avatarId = respJson['file']['_id'];

        // Register user
        var userData = {
          'username': _usernameController.text,
          'password': _passwordController.text,
          'name': _nameController.text,
          'dob': _dobController.text,
          'email': _emailController.text,
          'avatar': avatarId,
        };
        var userResp = await http.post(
          Uri.parse('https://dhkptsocial.onrender.com/users'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode(userData),
        );
        if (userResp.statusCode == 200 || userResp.statusCode == 201) {
          _showSnackbar('Đăng ký thành công', success: true);
          Navigator.of(context).pushReplacementNamed('/login');
        } else {
          _showSnackbar('Đăng ký thất bại');
        }
      } else {
        _showSnackbar('Upload avatar thất bại');
      }
    } catch (e) {
      _showSnackbar('Có lỗi xảy ra');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSnackbar(String message, {bool success = false}) {
    final color = success ? Colors.green : Colors.red;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _pickAvatar,
                child: CircleAvatar(
                  radius: 48,
                  backgroundImage: _avatar != null ? FileImage(_avatar!) : null,
                  backgroundColor: Colors.purple[200],
                  child: _avatar == null
                      ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(height: 8),
              const Text('Tải lên ảnh đại diện của bạn'),
              const SizedBox(height: 16),

              // Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Họ và tên'),
              ),
              const SizedBox(height: 8),

              // DOB
              TextFormField(
                controller: _dobController,
                decoration: const InputDecoration(labelText: 'Ngày sinh (YYYY-MM-DD)'),
                readOnly: true,
                onTap: () async {
                  DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime(2000),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    _dobController.text = DateFormat('yyyy-MM-dd').format(picked);
                  }
                },
              ),
              const SizedBox(height: 8),

              // Email
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email cá nhân'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),

              // Username
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Tên đăng nhập'),
              ),
              const SizedBox(height: 8),

              // Password
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
              ),
              const SizedBox(height: 8),

              // Re-password
              TextFormField(
                controller: _repasswordController,
                decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Register button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _register,
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Tạo tài khoản mới'),
                ),
              ),
              const SizedBox(height: 16),

              // Login link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Bạn đã có tài khoản? '),
                  TextButton(
                    onPressed: () => Navigator.of(context).pushReplacementNamed('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}