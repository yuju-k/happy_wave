import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'chat_load.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  String? _chatRoomId;
  String? _otherUserName;
  String? _otherProfileImage;
  final List<types.Message> _messages = [];
  bool _isLoading = true;
  final _auth = FirebaseAuth.instance;

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
      return;
    }

    final roomId = await fetchChatRoomIdForUser(user.uid);
    if (roomId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final otherUserName = await fetchOtherUserName(roomId, user.uid);
    final otherProfileImage = await fetchOtherUserProfileImage(
      roomId,
      user.uid,
    );

    setState(() {
      _chatRoomId = roomId;
      _otherUserName = otherUserName;
      _otherProfileImage = otherProfileImage;
      _isLoading = false;
    });

    _listenToMessages(roomId);
  }

  /// Firestore에서 실시간 메시지를 수신합니다.
  void _listenToMessages(String roomId) {
    FirebaseFirestore.instance
        .collection('chatrooms')
        .doc(roomId)
        .collection('messages')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          final messages =
              snapshot.docs.map((doc) {
                final data = doc.data();
                return types.TextMessage(
                  id: doc.id,
                  author: types.User(id: data['authorId'] as String),
                  createdAt:
                      (data['createdAt'] as Timestamp).millisecondsSinceEpoch,
                  text: data['text'] as String,
                );
              }).toList();

          setState(() {
            _messages.clear();
            _messages.addAll(messages);
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _chatRoomId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('대화')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Text('채팅방 ID: $_chatRoomId')),
            const SizedBox(height: 8),
            Center(child: Text('상대방: ${_otherUserName ?? '이름을 불러오는 중...'}')),
            const SizedBox(height: 8),
            // 프로필 이미지 주소 텍스트로 표시
            Center(
              child: Text(
                '프로필 이미지: ${_otherProfileImage ?? '이미지를 불러오는 중...'}',
                style: const TextStyle(fontSize: 12),
              ),
            ),
            Center(
              child:
                  _otherProfileImage != null
                      ? CircleAvatar(
                        radius: 30,
                        backgroundImage: NetworkImage(_otherProfileImage!),
                      )
                      : const Icon(Icons.person, size: 60),
            ),
            const Divider(),
            // TODO: 채팅 메시지 목록 UI 추가
          ],
        ),
      ),
    );
  }
}
