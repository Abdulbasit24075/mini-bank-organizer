import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../auth/signup_screen.dart';
import '../core/constants/app_colors.dart';
import '../core/services/relationship_service.dart';
import '../core/services/ledger_service.dart';
import '../core/services/online_payment_service.dart';
import '../shared/notebook_screen.dart';
import '../shared/payment_history_screen.dart';
import '../shared/statistics_screen.dart'; // 1. Import Statistics Screen
import '../shared/chatbot_screen.dart';

import 'create_bill_screen.dart';
import 'ai_receipt_bill_screen.dart';
import 'biller_ledger_screen.dart';
import 'biller_bills_history_screen.dart';
import 'biller_online_payment_requests_screen.dart';

class BillerDashboard extends StatelessWidget {
  const BillerDashboard({super.key});

  Future<Map<String, dynamic>> _getBillerAndAdminData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final firestore = FirebaseFirestore.instance;

    final billerDoc = await firestore.collection('users').doc(uid).get();
    final adminData = await RelationshipService().getAdminForBiller();

    return {'biller': billerDoc.data(), 'admin': adminData};
  }

  @override
  Widget build(BuildContext context) {
    final billerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Biller Dashboard'),
        centerTitle: true,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;

              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const SignupScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _getBillerAndAdminData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final biller = snapshot.data!['biller'];
              final admin = snapshot.data!['admin'];

              return Column(
                children: [
                  _infoCard(
                    title: 'Biller Details',
                    color: AppColors.primary,
                    textColor: Colors.white,
                    children: [
                      Text('Name: ${biller['name']}'),
                      Text('Email: ${biller['email']}'),
                      const Text('Role: Biller'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoCard(
                    title: 'My Admin',
                    color: AppColors.card,
                    textColor: AppColors.textPrimary,
                    children: admin != null
                        ? [
                            Text('Name: ${admin['name']}'),
                            Text('Email: ${admin['email']}'),
                          ]
                        : [const Text('No admin assigned')],
                  ),
                  if (admin != null) ...[
                    const SizedBox(height: 12),
                    _clearRequestCard(
                      context: context,
                      adminId: admin['uid'],
                      billerId: billerId,
                    ),
                  ],
                  const SizedBox(height: 20),
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1,
                      children: [
                        _actionCard(
                          icon: Icons.add_circle_outline,
                          label: 'Create Bill',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CreateBillScreen(),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.document_scanner_outlined,
                          label: 'AI Receipt Bill',
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AiReceiptBillScreen(),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.account_balance_wallet_outlined,
                          label: 'My Account',
                          color: AppColors.secondary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BillerLedgerScreen(),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.receipt_long_outlined,
                          label: 'Bill History',
                          color: AppColors.success,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const BillerBillsHistoryScreen(),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.payment_outlined,
                          label: 'Payment History',
                          color: AppColors.warning,
                          onTap: () {
                            if (admin == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No admin assigned yet'),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PaymentHistoryScreen(
                                  adminId: admin['uid'],
                                  billerId: billerId,
                                  billerName: biller['name'],
                                ),
                              ),
                            );
                          },
                        ),
                        // 2. Added Statistics Action Card
                        _actionCard(
                          icon: Icons.analytics,
                          label: 'Statistics',
                          color: AppColors.primary,
                          onTap: () {
                            if (admin == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No admin assigned yet'),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StatisticsScreen(
                                  adminId: admin['uid'],
                                  billerId: billerId,
                                  billerName: biller['name'],
                                ),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.menu_book_outlined,
                          label: 'Notebook',
                          color: AppColors.secondary,
                          onTap: () {
                            if (admin == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('No admin assigned yet'),
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => NotebookScreen(
                                  ownerId: billerId,
                                  ownerRole: 'biller',
                                  adminId: admin['uid'],
                                  billerId: billerId,
                                  billerName: biller['name'],
                                ),
                              ),
                            );
                          },
                        ),
                        _actionCard(
                          icon: Icons.chat,
                          label: 'Smart Assistant',
                          color: AppColors.primary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const ChatbotScreen(role: 'biller'),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: OnlinePaymentService().pendingRequestsForBiller(billerId),
        builder: (context, snapshot) {
          final pendingCount = snapshot.data?.docs.length ?? 0;

          return Stack(
            clipBehavior: Clip.none,
            children: [
              FloatingActionButton(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                child: const Icon(Icons.account_balance_wallet),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const BillerOnlinePaymentRequestsScreen(),
                    ),
                  );
                },
              ),
              if (pendingCount > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Text(
                      pendingCount > 99 ? '99+' : '$pendingCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  // ================= CLEAR REQUEST CARD =================
  Widget _clearRequestCard({
    required BuildContext context,
    required String adminId,
    required String billerId,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: LedgerService().ledgerStream(
        adminId: adminId,
        billerId: billerId,
      ),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final ledger = snapshot.data!.docs.first.data();
        final bool requestPending = ledger['clearRequestPending'] == true;

        if (!requestPending) {
          return const SizedBox();
        }

        return Card(
          color: AppColors.card,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Clear History Request',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.danger,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your admin wants to clear all bill and payment history. '
                  'Approve only if all accounts are settled.',
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          elevation: 3,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await LedgerService().approveClearHistory(
                              adminId: adminId,
                              billerId: billerId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('History cleared successfully'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        child: const Text('Approve'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          elevation: 3,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          try {
                            await LedgerService().rejectClearHistory(
                              adminId: adminId,
                              billerId: billerId,
                            );

                            if (!context.mounted) return;

                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Request rejected')),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        child: const Text('Reject'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoCard({
    required String title,
    required Color color,
    required Color textColor,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: color == AppColors.primary
            ? AppColors.primaryGradient
            : AppColors.cardGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: color == AppColors.card
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const SizedBox(height: 12),
            ...children.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: DefaultTextStyle(
                  style: TextStyle(color: textColor),
                  child: e,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      tween: Tween(begin: 0.96, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - value)),
          child: Transform.scale(scale: value, child: child),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppColors.softCardGradient(color),
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.softShadow,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
