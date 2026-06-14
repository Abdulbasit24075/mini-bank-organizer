import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/services/relationship_service.dart';
import '../shared/payment_history_screen.dart';
import 'admin_biller_ledger_screen.dart';

class LinkedUsersScreen extends StatelessWidget {
  const LinkedUsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RelationshipService();
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Billers'),
        backgroundColor: Colors.deepPurple,
      ),
      body: FutureBuilder(
        future: service.getLinkedUsersForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data as List<Map<String, dynamic>>;

          if (users.isEmpty) {
            return const Center(child: Text('No users added yet'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (_, i) {
              final biller = users[i];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(biller['name']),
                  subtitle: Text(
                    '${biller['email']}\nLong press to view payment history',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),

                  // Normal tap opens ledger/payment screen
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminBillerLedgerScreen(
                          billerId: biller['uid'],
                          billerName: biller['name'],
                          billerEmail: biller['email'],
                        ),
                      ),
                    );
                  },

                  // Long press opens payment history
                  onLongPress: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PaymentHistoryScreen(
                          adminId: adminId,
                          billerId: biller['uid'],
                          billerName: biller['name'],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}