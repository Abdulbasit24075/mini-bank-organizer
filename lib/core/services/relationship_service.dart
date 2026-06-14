import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RelationshipService {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // For ADMIN → get all linked users
  Future<List<Map<String, dynamic>>> getLinkedUsersForAdmin() async {
    final adminId = _auth.currentUser!.uid;

    final relations = await _firestore
        .collection('relationships')
        .where('createdBy', isEqualTo: adminId)
        .get();

    List<Map<String, dynamic>> users = [];

    for (var doc in relations.docs) {
      final userDoc = await _firestore
          .collection('users')
          .doc(doc['linkedUserId'])
          .get();

      users.add(userDoc.data()!);
    }

    return users;
  }

  // For BILLER → get admin details
  Future<Map<String, dynamic>?> getAdminForBiller() async {
    final billerId = _auth.currentUser!.uid;

    final relation = await _firestore
        .collection('relationships')
        .where('linkedUserId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (relation.docs.isEmpty) return null;

    final adminId = relation.docs.first['createdBy'];

    final adminDoc =
    await _firestore.collection('users').doc(adminId).get();

    return adminDoc.data();
  }
}
