import 'package:flutter/material.dart';

class UserInfoWidget extends StatelessWidget {
  final String? chatRoomId;
  final String? myName;
  final String? myProfileImage;
  final String? otherUserName;
  final String? otherProfileImage;

  const UserInfoWidget({
    super.key,
    this.chatRoomId,
    this.myName,
    this.myProfileImage,
    this.otherUserName,
    this.otherProfileImage,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: Text('채팅방 ID: ${chatRoomId ?? '불러오는 중...'}')),
        const SizedBox(height: 8),
        Center(child: Text('내 이름: ${myName ?? '이름을 불러오는 중...'}')),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '내 프로필 이미지: ${myProfileImage ?? '이미지를 불러오는 중...'}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Center(child: Text('상대방: ${otherUserName ?? '이름을 불러오는 중...'}')),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '프로필 이미지: ${otherProfileImage ?? '이미지를 불러오는 중...'}',
            style: const TextStyle(fontSize: 12),
          ),
        ),
        Center(
          child:
              otherProfileImage != null
                  ? CircleAvatar(
                    radius: 30,
                    backgroundImage: NetworkImage(otherProfileImage!),
                  )
                  : const Icon(Icons.person, size: 60),
        ),
        const Divider(),
      ],
    );
  }
}
