import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BillerBillsHistoryScreen extends StatelessWidget {
  const BillerBillsHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bills History'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('bills')
            .where('billerId', isEqualTo: billerId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No bills yet'));
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (_, i) {
              final bill = snapshot.data!.docs[i].data();
              return ListTile(
                title: Text(bill['title']),
                subtitle: Text(
                  'Amount: ${bill['totalAmount']}',
                ),
              );
            },
          );
        },
      ),
    );
  }
}
