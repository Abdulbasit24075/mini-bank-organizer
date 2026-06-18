import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/services/ledger_service.dart';
import '../core/services/relationship_service.dart';

class CreateBillScreen extends StatefulWidget {
  const CreateBillScreen({super.key});

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();

  File? _receiptImage;
  bool isLoading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _detailsCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickReceiptImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 35,
      maxWidth: 900,
    );

    if (pickedImage == null) return;

    setState(() {
      _receiptImage = File(pickedImage.path);
    });
  }

  Future<String> _receiptImageBase64() async {
    final image = _receiptImage;
    if (image == null) {
      throw Exception('Please pick a receipt image');
    }

    final bytes = await image.readAsBytes();
    return base64Encode(bytes);
  }

  Future<void> createBill() async {
    final title = _titleCtrl.text.trim();
    final billDetails = _detailsCtrl.text.trim();
    final amountText = _amountCtrl.text.trim();
    final amount = int.tryParse(amountText);

    if (title.isEmpty || billDetails.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all bill fields')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid amount greater than 0'),
        ),
      );
      return;
    }

    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please pick a receipt image')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final admin = await RelationshipService().getAdminForBiller();

      if (admin == null) {
        throw Exception('Admin not found for this biller');
      }

      final String billerId = FirebaseAuth.instance.currentUser!.uid;
      final String adminId = admin['uid'];
      final receiptImageBase64 = await _receiptImageBase64();

      await FirebaseFirestore.instance.collection('bills').add({
        'title': title,
        'billDetails': billDetails,
        'amount': amount,
        'totalAmount': amount,
        'paidAmount': 0,
        'receiptImageBase64': receiptImageBase64,
        'receiptImageUrl': '',
        'createdMethod': 'manual',
        'billerId': billerId,
        'adminId': adminId,
        'createdAt': Timestamp.now(),
      });

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
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            children: [
              _buildField(
                label: 'Bill Title',
                controller: _titleCtrl,
                keyboardType: TextInputType.text,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Bill Details',
                controller: _detailsCtrl,
                keyboardType: TextInputType.multiline,
                maxLines: 5,
              ),
              const SizedBox(height: 16),
              _buildField(
                label: 'Total Amount',
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: isLoading ? null : _pickReceiptImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pick Receipt Image'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.deepPurple,
                    side: const BorderSide(color: Colors.deepPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_receiptImage != null) ...[
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _receiptImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ],
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Bill',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required TextInputType keyboardType,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
