import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'invite_firebase.dart';

class InviteAlertListener {
  static List<String> _previousInvites = [];

  static void startListening(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .snapshots()
        .listen((doc) async {
          final data = doc.data();
          if (data == null) return;

          final List<String> currentInvites = List<String>.from(
            data['pendingInvites'] ?? [],
          );
          final List<String> newInvites =
              currentInvites
                  .where((uid) => !_previousInvites.contains(uid))
                  .toList();

          for (final fromUid in currentInvites) {
            final email = await InviteService().getEmailByUid(fromUid);
            if (context.mounted) {
              _showInviteDialog(context, fromUid, email);
            }
          }
        });
  }

  static void _showInviteDialog(
    BuildContext context,
    String fromUid,
    String fromEmail,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새로운 초대'),
            content: Text('$fromEmail 님이 초대했습니다.\n수락하시겠습니까?'),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await InviteService().declineInvite(fromUid);
                },
                child: const Text('거절'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await InviteService().acceptInvite(fromUid);
                },
                child: const Text('수락'),
              ),
            ],
          ),
    );
  }
}
