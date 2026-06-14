import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/ledger_service.dart';
import '../core/services/pdf_report_service.dart';
import '../shared/statistics_screen.dart';
import 'admin_biller_bill_history_screen.dart';

class AdminBillerLedgerScreen extends StatelessWidget {
  final String billerId;
  final String billerName;
  final String billerEmail;

  const AdminBillerLedgerScreen({
    super.key,
    required this.billerId,
    required this.billerName,
    required this.billerEmail,
  });

  @override
  Widget build(BuildContext context) {
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Biller Account'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: LedgerService().ledgerStream(
          adminId: adminId,
          billerId: billerId,
        ),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Ledger not found for this biller.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final ledger = snapshot.data!.docs.first.data();
          final int balance = ledger['balance'] as int;
          final bool clearRequestPending =
              ledger['clearRequestPending'] == true;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _card(title: 'Biller', content: '$billerName\n$billerEmail'),

                const SizedBox(height: 12),

                _card(
                  title: 'Ledger Summary',
                  content:
                      'Total Bills: ${ledger['totalBills']}\n'
                      'Total Paid: ${ledger['totalPaid']}\n'
                      '${balance >= 0 ? 'Remaining' : 'Advance'}: ${balance.abs()}',
                ),

                const SizedBox(height: 16),

                _actionButton(
                  text: 'View Bill History',
                  icon: Icons.receipt_long,
                  color: Colors.teal,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AdminBillerBillHistoryScreen(
                          adminId: adminId,
                          billerId: billerId,
                          billerName: billerName,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _actionButton(
                  text: 'View Statistics',
                  icon: Icons.analytics,
                  color: Colors.indigo,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StatisticsScreen(
                          adminId: adminId,
                          billerId: billerId,
                          billerName: billerName,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 12),

                _actionButton(
                  text: 'Export PDF',
                  icon: Icons.picture_as_pdf,
                  color: Colors.deepOrange,
                  onPressed: () => _exportPdf(context, adminId),
                ),

                const SizedBox(height: 12),

                _actionButton(
                  text: clearRequestPending
                      ? 'Clear Request Pending'
                      : 'Request Clear History',
                  icon: Icons.delete_sweep,
                  color: clearRequestPending ? Colors.grey : Colors.red,
                  onPressed: clearRequestPending
                      ? null
                      : () async {
                          try {
                            await LedgerService().requestClearHistory(
                              adminId: adminId,
                              billerId: billerId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Clear history request sent to biller',
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                ),

                const SizedBox(height: 16),

                _payBox(context, adminId),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, String adminId) async {
    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminId)
          .get();

      final adminName = adminDoc.data()?['name']?.toString() ?? 'Admin';

      await PdfReportService().generateAdminBillerStatement(
        adminId: adminId,
        billerId: billerId,
        adminName: adminName,
        billerName: billerName,
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Widget _payBox(BuildContext context, String adminId) {
    final TextEditingController ctrl = TextEditingController();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pay Combined Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                ),
                onPressed: () async {
                  final text = ctrl.text.trim();
                  final payAmount = int.tryParse(text);

                  if (payAmount == null || payAmount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please enter a valid payment amount.'),
                      ),
                    );
                    return;
                  }

                  try {
                    await LedgerService().payCombined(
                      adminId: adminId,
                      billerId: billerId,
                      payAmount: payAmount,
                    );

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Payment added successfully'),
                      ),
                    );

                    ctrl.clear();
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text(e.toString())));
                  }
                },
                child: const Text('Pay', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: Icon(icon),
        label: Text(text),
        onPressed: onPressed,
      ),
    );
  }

  Widget _card({required String title, required String content}) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: SizedBox(
        width: double.infinity,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(content),
            ],
          ),
        ),
      ),
    );
  }
}
