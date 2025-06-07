import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'profile_firebase.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // 상수 정의
  static const double _borderRadius = 12.0;
  static const Color _primaryColor = Color(0xFF44C2D0);
  static const double _spacing = 24.0;

  // 컨트롤러 및 상태 변수
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _statusController;
  File? _profileImage; // 새로 선택한 이미지
  String? _storedImageUrl; // 기존에 저장된 이미지 URL
  bool _isImageChanged = false; // 이미지가 변경되었는지 추적

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _statusController = TextEditingController();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  // 프로필 데이터 로드
  Future<void> _loadProfileData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final profileService = ProfileService();
    final data = await profileService.getProfile(user.uid);

    if (data != null && mounted) {
      setState(() {
        _nameController.text = data['name'] ?? '';
        _statusController.text = data['statusMessage'] ?? '';
        _storedImageUrl = data['profileImageUrl'];
      });
    }
  }

  // 프로필 저장 (이미지 업로드 포함)
  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('로그인된 사용자가 없습니다.');

      final name = _nameController.text.trim();
      final status = _statusController.text.trim();
      final service = ProfileService();

      // 이미지가 변경된 경우에만 업로드
      String? imageUrl = _storedImageUrl;
      if (_isImageChanged && _profileImage != null) {
        imageUrl = await service.uploadProfileImage(user.uid, _profileImage!);
      }

      // 프로필 정보 업데이트 (이미지 URL 포함)
      await service.updateProfile(user.uid, name, status);
      if (imageUrl != null) {
        await service.updateProfileImage(user.uid, imageUrl);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));

      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('저장 중 오류 발생: $e')));
    }
  }

  // 이미지 선택만 수행 (업로드는 저장 시)
  Future<void> _pickImage() async {
    if (!await Permission.photos.request().isGranted) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('사진 접근 권한이 필요합니다.')));
      return;
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null || !mounted) return;

    final imageFile = File(pickedFile.path);
    setState(() {
      _profileImage = imageFile;
      _isImageChanged = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final widgetWidth = screenWidth.clamp(300.0, 350.0);

    return Scaffold(
      appBar: AppBar(),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(_spacing),
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: _spacing / 2),
                _buildProfileForm(widgetWidth),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // 헤더 UI
  Widget _buildHeader() {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: _spacing),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '프로필 설정',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: _spacing / 2),
            Text(
              '프로필을 변경하려면 아래 정보를 입력하세요.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 16,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: _spacing),
          ],
        ),
      ),
    );
  }

  // 프로필 폼 컨테이너
  Widget _buildProfileForm(double widgetWidth) {
    return Container(
      width: widgetWidth,
      padding: const EdgeInsets.all(_spacing),
      decoration: BoxDecoration(
        color: const Color(0xFFD8F3F1),
        borderRadius: BorderRadius.circular(_borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(50),
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildProfileAvatar(widgetWidth),
          const SizedBox(height: _spacing),
          Form(
            key: _formKey,
            child: Column(
              children: [
                _buildNameField(widgetWidth),
                const SizedBox(height: _spacing),
                _buildStatusField(widgetWidth),
                const SizedBox(height: _spacing),
                _buildSaveButton(widgetWidth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 프로필 아바타
  Widget _buildProfileAvatar(double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: width * 0.13,
              backgroundColor: const Color(0xFFE0F7FA),
              backgroundImage:
                  _profileImage != null
                      ? FileImage(_profileImage!) // 새로 선택한 이미지 우선
                      : (_storedImageUrl != null
                          ? NetworkImage(_storedImageUrl!)
                          : null),
              child:
                  _profileImage == null && _storedImageUrl == null
                      ? Icon(
                        Icons.person,
                        size: width * 0.12,
                        color: _primaryColor,
                      )
                      : null,
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: GestureDetector(
                onTap: _pickImage, // 이미지 선택만 수행
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _primaryColor,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 텍스트 필드 데코레이션
  InputDecoration _textFieldDecoration(String label, {Icon? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: prefixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: _primaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_borderRadius),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  // 이름 입력 필드
  Widget _buildNameField(double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _nameController,
        decoration: _textFieldDecoration(
          '이름',
          prefixIcon: const Icon(Icons.person_outline, color: _primaryColor),
        ),
        validator:
            (value) =>
                value == null || value.trim().isEmpty ? '이름을 입력해주세요.' : null,
      ),
    );
  }

  // 상태 메시지 입력 필드
  Widget _buildStatusField(double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _statusController,
        decoration: _textFieldDecoration(
          '상태 메시지',
          prefixIcon: const Icon(Icons.edit_note, color: _primaryColor),
        ),
      ),
    );
  }

  // 저장 버튼
  Widget _buildSaveButton(double width) {
    return SizedBox(
      width: width,
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
        ),
        child: const Text('저장', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
