import 'package:cloud_firestore/cloud_firestore.dart';

import 'ledger_service.dart';

class OnlinePaymentService {
  final _db = FirebaseFirestore.instance;

  Future<void> createOnlinePaymentRequest({
    required String adminId,
    required String billerId,
    required int amount,
    required String paymentApp,
    required String referenceNumber,
    required String note,
  }) async {
    await _db.collection('online_payment_requests').add({
      'adminId': adminId,
      'billerId': billerId,
      'amount': amount,
      'paymentApp': paymentApp,
      'referenceNumber': referenceNumber,
      'note': note,
      'status': 'pending',
      'createdAt': Timestamp.now(),
      'confirmedAt': null,
      'rejectedAt': null,
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> pendingRequestsForBiller(
    String billerId,
  ) {
    return _db
        .collection('online_payment_requests')
        .where('billerId', isEqualTo: billerId)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> confirmOnlinePaymentRequest({
    required String requestId,
    required String adminId,
    required String billerId,
    required int amount,
  }) async {
    final requestRef = _db.collection('online_payment_requests').doc(requestId);
    final requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      throw Exception('Online payment request not found.');
    }

    final request = requestDoc.data()!;

    if (request['status'] != 'pending') {
      throw Exception('This online payment request is already handled.');
    }

    await LedgerService().payCombined(
      adminId: adminId,
      billerId: billerId,
      payAmount: amount,
    );

    await requestRef.update({
      'status': 'confirmed',
      'confirmedAt': Timestamp.now(),
    });
  }

  Future<void> rejectOnlinePaymentRequest(String requestId) async {
    final requestRef = _db.collection('online_payment_requests').doc(requestId);
    final requestDoc = await requestRef.get();

    if (!requestDoc.exists) {
      throw Exception('Online payment request not found.');
    }

    final request = requestDoc.data()!;

    if (request['status'] != 'pending') {
      throw Exception('This online payment request is already handled.');
    }

    await requestRef.update({
      'status': 'rejected',
      'rejectedAt': Timestamp.now(),
    });
  }
}
