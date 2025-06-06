import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/user_service.dart';
import 'widgets/chat_input/chat_input.dart';
import 'widgets/chat_output.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _chatRoomId;
  String? _myName;
  String? _otherUserName;
  String? _otherUserId;
  String? _otherProfileImage;
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// 채팅방 정보와 사용자 데이터를 초기화합니다.
  Future<void> _initializeChat() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showErrorSnackBar('로그인이 필요합니다.');
        setState(() => _isLoading = false);
        return;
      }

      final roomId = await _userService.fetchChatRoomIdForUser(user.uid);
      if (roomId == null) {
        _showErrorSnackBar('채팅방 정보를 불러오지 못했습니다.');
        setState(() => _isLoading = false);
        return;
      }

      final myProfile = await _userService.fetchMyProfile(user.uid);
      final otherUserInfo = await _userService.fetchOtherUserInfo(
        roomId,
        user.uid,
      );

      if (myProfile == null || myProfile['name'] == null) {
        _showErrorSnackBar('내 프로필 정보를 불러오지 못했습니다.');
      }

      setState(() {
        _chatRoomId = roomId;
        _myName = myProfile?['name'];
        _otherUserId = otherUserInfo?['otherUserId'];
        _otherUserName = otherUserInfo?['otherName'];
        _otherProfileImage = otherUserInfo?['otherProfileImageUrl'];

        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackBar('채팅 초기화 중 오류가 발생했습니다: $e');
      setState(() => _isLoading = false);
    }
  }

  /// 오류 메시지를 SnackBar로 표시합니다.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _chatRoomId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserName ?? ''),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
                _otherProfileImage != null
                    ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(_otherProfileImage!),
                    )
                    : const CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white60,
                      child: Icon(Icons.person, size: 22),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: ChatOutput(
              chatRoomId: _chatRoomId!,
              myUserId: _auth.currentUser!.uid,
              myName: _myName!,
              otherUserId: _otherUserId,
              otherUserName: _otherUserName,
            ),
          ),
          ChatInput(
            chatRoomId: _chatRoomId!,
            myUserId: _auth.currentUser!.uid,
            myName: _myName!,
          ),
        ],
      ),
    );
  }
}
