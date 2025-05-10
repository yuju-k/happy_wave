import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
}
