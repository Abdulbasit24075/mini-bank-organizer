import 'package:cloud_firestore/cloud_firestore.dart';

class NotebookService {
  final _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> notebookStream({
    required String ownerId,
    required String billerId,
  }) {
    return _db
        .collection('notebook_entries')
        .where('ownerId', isEqualTo: ownerId)
        .where('billerId', isEqualTo: billerId)
        .snapshots();
  }

  Future<void> createSummary({
    required String ownerId,
    required String ownerRole,
    required String adminId,
    required String billerId,
    required String billerName,
    required String monthDetail,
    required String comment,
  }) async {
    final ledgerQuery = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (ledgerQuery.docs.isEmpty) {
      throw Exception('Ledger not found for this notebook.');
    }

    final ledger = ledgerQuery.docs.first.data();
    final now = Timestamp.now();

    await _db.collection('notebook_entries').add({
      'ownerId': ownerId,
      'ownerRole': ownerRole,
      'adminId': adminId,
      'billerId': billerId,
      'billerName': billerName,
      'monthDetail': monthDetail,
      'comment': comment,
      'totalBills': ledger['totalBills'] ?? 0,
      'totalPaid': ledger['totalPaid'] ?? 0,
      'balance': ledger['balance'] ?? 0,
      'createdAt': now,
    });
  }

  Future<void> updateEntry({
    required String entryId,
    required String ownerId,
    required String monthDetail,
    required String comment,
  }) async {
    final doc = await _db.collection('notebook_entries').doc(entryId).get();

    if (!doc.exists || doc.data()?['ownerId'] != ownerId) {
      throw Exception('Notebook record not found.');
    }

    await doc.reference.update({
      'monthDetail': monthDetail,
      'comment': comment,
      'updatedAt': Timestamp.now(),
    });
  }

  Future<void> deleteEntry({
    required String entryId,
    required String ownerId,
  }) async {
    final doc = await _db.collection('notebook_entries').doc(entryId).get();

    if (!doc.exists || doc.data()?['ownerId'] != ownerId) {
      throw Exception('Notebook record not found.');
    }

    await doc.reference.delete();
  }
}
