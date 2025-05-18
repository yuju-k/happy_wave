import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'services/message_service.dart';
import 'services/user_service.dart';
import 'widgets/chat_input.dart';
import 'widgets/chat_output.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _chatRoomId;
  String? _myName;
  //String? _myProfileImage;
  String? _otherUserName;
  String? _otherProfileImage;
  //final List<types.Message> _messages = [];
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;
  final _userService = UserService();
  //final _messageService = MessageService();

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  /// 채팅방 정보와 메시지를 초기화합니다.
  Future<void> _initializeChat() async {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('로그인이 필요합니다.')));
      return;
    }

    final roomId = await _userService.fetchChatRoomIdForUser(user.uid);
    if (roomId == null) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('채팅방 정보를 불러오지 못했습니다.')));
      return;
    }

    final myProfile = await _userService.fetchMyProfile(user.uid);
    final otherUserInfo = await _userService.fetchOtherUserInfo(
      roomId,
      user.uid,
    );

    if (myProfile == null || myProfile['name'] == null) {
      print('Failed to load my profile: $myProfile');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('내 프로필 정보를 불러오지 못했습니다.')));
    }

    setState(() {
      _chatRoomId = roomId;
      _myName = myProfile?['name'] ?? '익명 사용자';
      //_myProfileImage = myProfile?['profileImageUrl'];
      _otherUserName = otherUserInfo?['name'] ?? '알 수 없는 사용자';
      _otherProfileImage = otherUserInfo?['profileImageUrl'];
      _isLoading = false;
    });

    //_subscribeToMessages(roomId);
  }

  /// Firestore에서 실시간 메시지를 구독합니다.
  // void _subscribeToMessages(String roomId) {
  //   _messageService.getMessagesStream(roomId).listen((messages) {
  //     setState(() {
  //       _messages.clear();
  //       _messages.addAll(messages);
  //     });
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _chatRoomId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_otherUserName ?? '상대방 이름 불러오는 중...'),
        centerTitle: true, // 제목을 중앙에 배치
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child:
                _otherProfileImage != null
                    ? CircleAvatar(
                      radius: 22,
                      backgroundImage: NetworkImage(_otherProfileImage!),
                    )
                    : CircleAvatar(
                      radius: 22,
                      backgroundColor: Colors.white60,
                      child: Icon(Icons.person, size: 22),
                    ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: ChatOutput()),
          Expanded(
            child: ChatWidget(
              chatRoomId: _chatRoomId,
              myUserId: _auth.currentUser?.uid,
              myName: _myName,
            ),
          ),
        ],
      ),
    );
  }
}
