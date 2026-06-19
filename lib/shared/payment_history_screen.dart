import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../core/services/ledger_service.dart';

class PaymentHistoryScreen extends StatelessWidget {
  final String adminId;
  final String billerId;
  final String billerName;

  const PaymentHistoryScreen({
    super.key,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('$billerName Payments'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: LedgerService().paymentHistoryStream(
            adminId: adminId,
            billerId: billerId,
          ),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No payment history yet.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final payment = snapshot.data!.docs[index].data();

                final Timestamp? timestamp = payment['createdAt'];
                final String date = timestamp == null
                    ? 'N/A'
                    : timestamp.toDate().toString().split(' ')[0];

                final int paidAmount = payment['paidAmount'] ?? 0;

                final int totalBillsBefore = payment['totalBillsBefore'] ?? 0;
                final int totalPaidBefore = payment['totalPaidBefore'] ?? 0;
                final int balanceBefore = payment['balanceBefore'] ?? 0;

                final int totalBillsAfter = payment['totalBillsAfter'] ?? 0;
                final int totalPaidAfter = payment['totalPaidAfter'] ?? 0;
                final int balanceAfter = payment['balanceAfter'] ?? 0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.softCardGradient(AppColors.success),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                    boxShadow: AppColors.softShadow,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Paid Amount: Rs $paidAmount',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('Date: $date'),

                        const Divider(height: 24),

                        const Text(
                          'Before Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('Total Bills: Rs $totalBillsBefore'),
                        Text('Total Paid: Rs $totalPaidBefore'),
                        Text(
                          balanceBefore >= 0
                              ? 'Remaining: Rs $balanceBefore'
                              : 'Advance: Rs ${balanceBefore.abs()}',
                        ),

                        const Divider(height: 24),

                        const Text(
                          'After Payment',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Text('Total Bills: Rs $totalBillsAfter'),
                        Text('Total Paid: Rs $totalPaidAfter'),
                        Text(
                          balanceAfter >= 0
                              ? 'Remaining: Rs $balanceAfter'
                              : 'Advance: Rs ${balanceAfter.abs()}',
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
