import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

              final Timestamp? timestamp = bill['createdAt'];
              final String date = timestamp == null
                  ? 'N/A'
                  : timestamp.toDate().toString().split(' ')[0];

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.receipt_long,
                    color: Colors.deepPurple,
                  ),
                  title: Text(
                    bill['title'] ?? 'Untitled Bill',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Date: $date'),
                  trailing: Text(
                    'Rs ${bill['totalAmount'] ?? 0}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}