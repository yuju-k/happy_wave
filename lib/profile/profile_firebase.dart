import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

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
