import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // 저장된 프로필 정보를 가져옴
  Future<Map<String, dynamic>?> getProfile(String uid) async {
    final docRef = _firestore.collection('users').doc(uid);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      return docSnapshot.data();
    } else {
      return null;
    }
  }

  Future<void> updateProfile(
    String uid,
    String name,
    String statusMessage,
  ) async {
    final docRef = _firestore.collection('users').doc(uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      throw Exception('User with uid $uid does not exist.');
    }

    await docRef.set({
      'name': name,
      'statusMessage': statusMessage,
    }, SetOptions(merge: true));

    // user의 이메일 정보를 받아와서 기록
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (userDoc.exists) {
      final userData = userDoc.data();
      if (userData != null && userData.containsKey('email')) {
        final email = userData['email'];
        await _firestore.collection('system_log').doc(uid).set({
          'email': email,
        }, SetOptions(merge: true));
      }
    }
    debugPrint('로그인 로그 기록 완료: $uid');
  }

  Future<void> updateProfileImage(String uid, String imageUrl) async {
    final docRef = _firestore.collection('users').doc(uid);
    await docRef.set({'profileImageUrl': imageUrl}, SetOptions(merge: true));
  }

  Future<String> uploadProfileImage(String uid, File imageFile) async {
    final storageRef = _storage.ref().child('profile_images/$uid.jpg');
    await storageRef.putFile(imageFile);
    return await storageRef.getDownloadURL();
  }
}
