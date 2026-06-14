import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/services/ledger_service.dart';

class BillerLedgerScreen extends StatelessWidget {
  const BillerLedgerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final billerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('My Account'),
        backgroundColor: Colors.deepPurple,
      ),
      body: StreamBuilder(
        stream: LedgerService().ledgerStreamForBiller(billerId),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No ledger found. Please wait until admin links your account.',
                textAlign: TextAlign.center,
              ),
            );
          }

          final ledger = snapshot.data!.docs.first.data();
          final balance = ledger['balance'] as int;

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Total Bills: ${ledger['totalBills']}\n'
                      'Total Paid: ${ledger['totalPaid']}\n'
                      '${balance >= 0 ? 'Remaining' : 'Advance'}: ${balance.abs()}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}