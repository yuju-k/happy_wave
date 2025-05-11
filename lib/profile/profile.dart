import 'package:flutter/material.dart';

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
  static const double _textFieldWidth = 450.0; // 텍스트 필드 및 버튼 너비 설정

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
  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('프로필이 저장되었습니다.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 프로필 사진
                _buildProfileAvatar(),
                const SizedBox(height: 32),

                // 이름 입력 필드
                _buildNameField(),
                const SizedBox(height: 20),

                // 상태 메시지 입력 필드
                _buildStatusField(),
                const SizedBox(height: 30),

                // 저장 버튼
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 프로필 사진 위젯
  Widget _buildProfileAvatar() {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Color(0xFFE0F7FA),
          child: Icon(Icons.person, size: 50, color: Color(0xFF44C2D0)),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF44C2D0),
            ),
            padding: const EdgeInsets.all(6),
            child: const Icon(Icons.camera_alt, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  /// 텍스트 필드 스타일 정의
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
        borderSide: const BorderSide(color: _primaryColor, width: 2.0),
      ),
      filled: true,
      fillColor: Colors.white,
    );
  }

  /// 이름 입력 필드 위젯
  Widget _buildNameField() {
    return SizedBox(
      width: _textFieldWidth,
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
  Widget _buildStatusField() {
    return SizedBox(
      width: _textFieldWidth,
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
  Widget _buildSaveButton() {
    return SizedBox(
      width: _textFieldWidth, // 텍스트 필드와 동일한 너비로 설정
      child: ElevatedButton(
        onPressed: _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_borderRadius),
          ),
          backgroundColor: _primaryColor,
        ),
        child: const Text('저장', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}
