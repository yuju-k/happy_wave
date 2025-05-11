import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'profile_firebase.dart';

class ProfilePage extends StatefulWidget {
  final String? initialName;
  final String? initialStatus;

  const ProfilePage({super.key, this.initialName, this.initialStatus});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _statusController;

  static const double _borderRadius = 12.0;
  static const Color _primaryColor = Color(0xFF44C2D0);
  static const double _spacing = 24.0; // 위젯 간 간격 통일

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _statusController = TextEditingController(text: widget.initialStatus ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  /// 프로필 정보를 저장하고 성공 메시지를 표시합니다.
  void _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) {
          throw Exception('로그인된 사용자가 없습니다.');
        }

        final name = _nameController.text.trim();
        final status = _statusController.text.trim();

        final service = ProfileService();
        await service.updateProfile(user.uid, name, status);

        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));

        // HomePage로 이동 (기존 라우트 모두 제거)
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('저장 중 오류 발생: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double widgetWidth = screenWidth.clamp(300.0, 600.0);

    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(_spacing),
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: _spacing / 2), // 여백 약간 줄임
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
                      const Spacer(), // 키보드와 겹치지 않게 하단 공간 확보
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// 프로필 사진 위젯
  Widget _buildProfileAvatar(double width) {
    return SizedBox(
      width: width,
      child: Center(
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: width * 0.13, // 더 큰 아바타 크기
              backgroundColor: const Color(0xFFE0F7FA),
              child: Icon(
                Icons.person,
                size: width * 0.12, // 비례한 아이콘 크기
                color: _primaryColor,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _primaryColor,
                ),
                padding: const EdgeInsets.all(8), // 약간 더 큰 패딩
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 텍스트 필드 스타일 정의
  InputDecoration _textFieldDecoration(String label, {Icon? prefixIcon}) {
    return InputDecoration(
      labelText: label,
      prefixIcon:
          prefixIcon != null
              ? Icon(
                prefixIcon.icon,
                color: _primaryColor, // 아이콘 색상 설정
              )
              : null,
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
        borderSide: const BorderSide(color: _primaryColor, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  /// 이름 입력 필드 위젯
  Widget _buildNameField(double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _nameController,
        decoration: _textFieldDecoration(
          '이름',
          prefixIcon: const Icon(Icons.person_outline),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return '이름을 입력해주세요.';
          }
          return null;
        },
      ),
    );
  }

  /// 상태 메시지 입력 필드 위젯
  Widget _buildStatusField(double width) {
    return SizedBox(
      width: width,
      child: TextFormField(
        controller: _statusController,
        decoration: _textFieldDecoration(
          '상태 메시지',
          prefixIcon: const Icon(Icons.edit_note),
        ),
        maxLines: 2,
      ),
    );
  }

  /// 저장 버튼 위젯
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
          foregroundColor: Colors.white, // 텍스트 및 아이콘 색상
        ),
        child: const Text('저장', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
