import 'package:cloud_firestore/cloud_firestore.dart';

class Member {
  final String uid;
  final String email;
  bool chatOriginalToggleEnabled;
  bool chatOriginalViewEnabled;
  final String chatroomId;
  final bool connectStatus;
  final DateTime createdAt;
  final String homeId;
  String name;
  final List<String> pendingInvites;
  final String role;
  String statusMessage;

  Member({
    required this.uid,
    required this.email,
    required this.chatOriginalToggleEnabled,
    required this.chatOriginalViewEnabled,
    required this.chatroomId,
    required this.connectStatus,
    required this.createdAt,
    required this.homeId,
    required this.name,
    required this.pendingInvites,
    required this.role,
    required this.statusMessage,
  });

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      uid: json['uid'] ?? '',
      email: json['email'] ?? '',
      chatOriginalToggleEnabled: json['chatOriginalToggleEnabled'] ?? false,
      chatOriginalViewEnabled: json['chatOriginalViewEnabled'] ?? false,
      chatroomId: json['chatroomId'] ?? '',
      connectStatus: json['connectStatus'] ?? false,
      createdAt: _parseTimestamp(json['createdAt']),
      homeId: json['homeId'] ?? '',
      name: json['name'] ?? '',
      pendingInvites: List<String>.from(json['pendingInvites'] ?? []),
      role: json['role'] ?? 'user',
      statusMessage: json['statusMessage'] ?? '',
    );
  }

  factory Member.of({required String uid, required String email}) {
    return Member(
      uid: uid,
      email: email,
      chatOriginalToggleEnabled: false,
      chatOriginalViewEnabled: false,
      chatroomId: '',
      connectStatus: false,
      createdAt: DateTime.now(),
      homeId: '',
      name: '',
      pendingInvites: [],
      role: 'user',
      statusMessage: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'chatOriginalToggleEnabled': chatOriginalToggleEnabled,
      'chatOriginalViewEnabled': chatOriginalViewEnabled,
      'chatroomId': chatroomId,
      'connectStatus': connectStatus,
      'createdAt': createdAt.toIso8601String(),
      'homeId': homeId,
      'name': name,
      'pendingInvites': pendingInvites,
      'role': role,
      'statusMessage': statusMessage,
    };
  }

  static DateTime _parseTimestamp(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    if (value is Map && value.containsKey('_seconds')) {
      return DateTime.fromMillisecondsSinceEpoch(value['_seconds'] * 1000);
    }
    if (value is Timestamp) {
      return value.toDate();
    }
    return DateTime.now();
  }

  void updateChatOriginalToggleEnabled(bool newValue) {
    chatOriginalToggleEnabled = newValue;
  }

  void updateChatOriginalViewEnabled(bool newValue) {
    chatOriginalViewEnabled = newValue;
  }
}
