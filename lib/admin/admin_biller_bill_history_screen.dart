import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../shared/receipt_viewer_screen.dart';

class AdminBillerBillHistoryScreen extends StatelessWidget {
  final String adminId;
  final String billerId;
  final String billerName;

  const AdminBillerBillHistoryScreen({
    super.key,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('$billerName Bills'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('adminId', isEqualTo: adminId)
            .where('billerId', isEqualTo: billerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bills yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final bill = snapshot.data!.docs[index].data();
              final details = (bill['billDetails'] ?? '').toString();
              final receiptImageUrl = (bill['receiptImageUrl'] ?? '')
                  .toString();
              final receiptImageBase64 = (bill['receiptImageBase64'] ?? '')
                  .toString();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.receipt_long,
                            color: Colors.deepPurple,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              (bill['title'] ?? 'Untitled Bill').toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'Rs ${_billAmount(bill)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.deepPurple,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Date: ${_formatTimestamp(bill['createdAt'])}'),
                      if (details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(details),
                      ],
                      if (receiptImageUrl.isNotEmpty ||
                          receiptImageBase64.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ReceiptViewerScreen(
                                    imageUrl: receiptImageUrl,
                                    imageBase64: receiptImageBase64,
                                    title: (bill['title'] ?? 'Receipt')
                                        .toString(),
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('View Receipt'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTimestamp(dynamic value) {
    if (value is Timestamp) {
      return DateFormat('dd MMM yyyy, hh:mm a').format(value.toDate());
    }

    return 'N/A';
  }

  int _billAmount(Map<String, dynamic> bill) {
    final amount = bill['amount'] ?? bill['totalAmount'];
    if (amount is int) return amount;
    if (amount is num) return amount.toInt();
    return 0;
  }
}
