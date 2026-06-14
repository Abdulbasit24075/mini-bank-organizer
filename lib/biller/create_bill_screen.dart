import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/services/relationship_service.dart';
import '../core/services/ledger_service.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  bool isLoading = false;
  Future<void> createBill() async {
    if (_titleCtrl.text.trim().isEmpty ||
        _amountCtrl.text.trim().isEmpty) {
      return;
    }

    setState(() => isLoading = true);

    try {
      // 🔹 Get admin linked with this biller
      final admin =
      await RelationshipService().getAdminForBiller();

      if (admin == null) {
        throw Exception('Admin not found for this biller');
      }

      final int? amount = int.tryParse(_amountCtrl.text.trim());

      if (amount == null || amount <= 0) {
        throw Exception('Please enter a valid amount greater than 0');
      }
      final String billerId =
          FirebaseAuth.instance.currentUser!.uid;
      final String adminId = admin['uid'];

      // ================== 1️⃣ CREATE BILL (HISTORY) ==================
      await FirebaseFirestore.instance.collection('bills').add({
        'title': _titleCtrl.text.trim(),
        'totalAmount': amount,
        'paidAmount': 0,
        'billerId': billerId,
        'adminId': adminId,
        'createdAt': Timestamp.now(),
      });

      // ✅ PART 4 — ONLY ADD THIS LINE (as per screenshot)


      // ================== 2️⃣ UPDATE LEDGER (TOTALS) ==================
      await LedgerService().addBillAmount(
        adminId: adminId,
        billerId: billerId,
        amount: amount,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bill created successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Create Bill'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildField(
              label: 'Bill Title',
              controller: _titleCtrl,
              keyboardType: TextInputType.text,
            ),
            const SizedBox(height: 16),
            _buildField(
              label: 'Total Amount',
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isLoading ? null : createBill,
                child: isLoading
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  'Create Bill',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
