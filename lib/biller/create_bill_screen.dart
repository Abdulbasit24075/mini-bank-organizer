import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Create Bill'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 460),
            tween: Tween(begin: 0.95, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - value)),
                child: Transform.scale(scale: value, child: child),
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: AppColors.border),
              ),
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.receipt_long,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manual Bill Entry',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isLoading ? null : _pickReceiptImage,
                      icon: const Icon(Icons.image),
                      label: const Text('Pick Receipt Image'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  if (_receiptImage != null) ...[
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        _receiptImage!,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: isLoading ? null : createBill,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Create Bill'),
                    ),
                  ),
                ],
              ),
            ),
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
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }
}
