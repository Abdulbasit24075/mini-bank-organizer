import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<String> getCurrentUserRole() async {
    final uid = _auth.currentUser!.uid;

    final doc =
    await _firestore.collection('users').doc(uid).get();

    return doc['role'];
  }
}
