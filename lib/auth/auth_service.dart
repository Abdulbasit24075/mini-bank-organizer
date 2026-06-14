import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER USER WITH ROLE
  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role, // admin | biller
  }) async {
    // Safety check
    if (role != 'admin' && role != 'biller') {
      throw Exception('Invalid role selected');
    }

    UserCredential cred =
    await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await _firestore.collection('users').doc(cred.user!.uid).set({
      'uid': cred.user!.uid,
      'name': name,
      'email': email,
      'role': role, // ✅ USER-SELECTED ROLE
    });
  }

  // LOGIN USER
  Future<void> login({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  // LOGOUT USER
  Future<void> logout() async {
    await _auth.signOut();
  }
}
