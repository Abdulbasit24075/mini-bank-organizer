import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerService {
  final _db = FirebaseFirestore.instance;

  /// Create ledger when Admin adds a Biller
  Future<void> createLedger({
    required String adminId,
    required String billerId,
  }) async {
    final q = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (q.docs.isNotEmpty) return;

    await _db.collection('ledgers').add({
      'adminId': adminId,
      'billerId': billerId,
      'totalBills': 0,
      'totalPaid': 0,
      'balance': 0,
      'clearRequestPending': false,
      'clearRequestedAt': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Add bill amount when biller creates a bill
  Future<void> addBillAmount({
    required String adminId,
    required String billerId,
    required int amount,
  }) async {
    final q = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Ledger not found');
    }

    final ref = q.docs.first.reference;
    final data = q.docs.first.data();

    final totalBills = (data['totalBills'] as int) + amount;
    final totalPaid = data['totalPaid'] as int;

    await ref.update({
      'totalBills': totalBills,
      'balance': totalBills - totalPaid,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Admin pays one combined amount and saves payment history
  Future<void> payCombined({
    required String adminId,
    required String billerId,
    required int payAmount,
  }) async {
    final q = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Ledger not found');
    }

    final ref = q.docs.first.reference;
    final data = q.docs.first.data();

    final int totalBillsBefore = data['totalBills'] as int;
    final int totalPaidBefore = data['totalPaid'] as int;
    final int balanceBefore = data['balance'] as int;

    final int totalBillsAfter = totalBillsBefore;
    final int totalPaidAfter = totalPaidBefore + payAmount;
    final int balanceAfter = totalBillsAfter - totalPaidAfter;

    await ref.update({
      'totalPaid': totalPaidAfter,
      'balance': balanceAfter,
      'updatedAt': Timestamp.now(),
    });

    await _db.collection('payments').add({
      'adminId': adminId,
      'billerId': billerId,
      'paidAmount': payAmount,
      'totalBillsBefore': totalBillsBefore,
      'totalPaidBefore': totalPaidBefore,
      'balanceBefore': balanceBefore,
      'totalBillsAfter': totalBillsAfter,
      'totalPaidAfter': totalPaidAfter,
      'balanceAfter': balanceAfter,
      'createdAt': Timestamp.now(),
    });
  }

  /// Admin requests clear history.
  /// Allowed only when balance is zero.
  Future<void> requestClearHistory({
    required String adminId,
    required String billerId,
  }) async {
    final q = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Ledger not found');
    }

    final ref = q.docs.first.reference;
    final data = q.docs.first.data();

    final int balance = data['balance'] as int;

    if (balance != 0) {
      throw Exception(
        'Clear request allowed only when Remaining/Advance is zero.',
      );
    }

    await ref.update({
      'clearRequestPending': true,
      'clearRequestedAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Biller rejects clear history request.
  Future<void> rejectClearHistory({
    required String adminId,
    required String billerId,
  }) async {
    final q = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (q.docs.isEmpty) {
      throw Exception('Ledger not found');
    }

    await q.docs.first.reference.update({
      'clearRequestPending': false,
      'clearRequestedAt': null,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Biller approves clear history request.
  /// Deletes bills + payments for this admin-biller pair and resets ledger.
  Future<void> approveClearHistory({
    required String adminId,
    required String billerId,
  }) async {
    final ledgerQuery = await _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .get();

    if (ledgerQuery.docs.isEmpty) {
      throw Exception('Ledger not found');
    }

    final ledgerRef = ledgerQuery.docs.first.reference;
    final ledgerData = ledgerQuery.docs.first.data();

    final int balance = ledgerData['balance'] as int;
    final bool clearRequestPending =
        ledgerData['clearRequestPending'] == true;

    if (!clearRequestPending) {
      throw Exception('No clear history request found.');
    }

    if (balance != 0) {
      throw Exception(
        'History can be cleared only when Remaining/Advance is zero.',
      );
    }

    final billsQuery = await _db
        .collection('bills')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    final paymentsQuery = await _db
        .collection('payments')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .get();

    final batch = _db.batch();

    for (final doc in billsQuery.docs) {
      batch.delete(doc.reference);
    }

    for (final doc in paymentsQuery.docs) {
      batch.delete(doc.reference);
    }

    batch.update(ledgerRef, {
      'totalBills': 0,
      'totalPaid': 0,
      'balance': 0,
      'clearRequestPending': false,
      'clearRequestedAt': null,
      'updatedAt': Timestamp.now(),
    });

    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ledgerStream({
    required String adminId,
    required String billerId,
  }) {
    return _db
        .collection('ledgers')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> ledgerStreamForBiller(
      String billerId,
      ) {
    return _db
        .collection('ledgers')
        .where('billerId', isEqualTo: billerId)
        .limit(1)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> paymentHistoryStream({
    required String adminId,
    required String billerId,
  }) {
    return _db
        .collection('payments')
        .where('adminId', isEqualTo: adminId)
        .where('billerId', isEqualTo: billerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> paymentHistoryForBiller(
      String billerId,
      ) {
    return _db
        .collection('payments')
        .where('billerId', isEqualTo: billerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}