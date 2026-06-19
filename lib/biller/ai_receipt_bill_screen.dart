import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/constants/app_colors.dart';
import '../core/services/groq_receipt_service.dart';
import '../core/services/ledger_service.dart';
import '../core/services/relationship_service.dart';

class AiReceiptBillScreen extends StatefulWidget {
  const AiReceiptBillScreen({super.key});

  @override
  State<AiReceiptBillScreen> createState() => _AiReceiptBillScreenState();
}

class _AiReceiptBillScreenState extends State<AiReceiptBillScreen> {
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _detailsCtrl = TextEditingController();
  final TextEditingController _amountCtrl = TextEditingController();
  final GroqReceiptService _groqReceiptService = GroqReceiptService();

  File? _receiptImage;
  String? _rawResponse;
  bool isExtracting = false;
  bool isSaving = false;

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
      _rawResponse = null;
      _titleCtrl.clear();
      _detailsCtrl.clear();
      _amountCtrl.clear();
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

  Future<void> _extractWithAi() async {
    final image = _receiptImage;
    if (image == null) {
      _showMessage('Please pick a receipt image first.');
      return;
    }

    setState(() => isExtracting = true);

    try {
      final result = await _groqReceiptService.extractReceipt(image);

      if (!mounted) return;

      setState(() {
        _titleCtrl.text = result.title;
        _detailsCtrl.text = result.billDetails;
        _amountCtrl.text = result.totalAmount.toString();
        _rawResponse = result.rawResponse;
      });

      _showMessage('Receipt extracted. Please review before creating bill.');
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isExtracting = false);
      }
    }
  }

  Future<void> _createBill() async {
    final title = _titleCtrl.text.trim();
    final billDetails = _detailsCtrl.text.trim();
    final amount = int.tryParse(_amountCtrl.text.trim());

    if (_receiptImage == null) {
      _showMessage('Please pick a receipt image.');
      return;
    }

    if (title.isEmpty) {
      _showMessage('Bill title cannot be empty.');
      return;
    }

    if (billDetails.isEmpty) {
      _showMessage('Bill details cannot be empty.');
      return;
    }

    if (amount == null || amount <= 0) {
      _showMessage('Please enter a valid total amount.');
      return;
    }

    setState(() => isSaving = true);

    try {
      final admin = await RelationshipService().getAdminForBiller();

      if (admin == null) {
        throw Exception('Admin not found for this biller');
      }

      final billerId = FirebaseAuth.instance.currentUser!.uid;
      final adminId = admin['uid'].toString();
      final receiptImageBase64 = await _receiptImageBase64();

      await FirebaseFirestore.instance.collection('bills').add({
        'title': title,
        'billDetails': billDetails,
        'amount': amount,
        'totalAmount': amount,
        'paidAmount': 0,
        'receiptImageBase64': receiptImageBase64,
        'receiptImageUrl': '',
        'createdMethod': 'ai',
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

      _showMessage('AI receipt bill created successfully');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      _showMessage(e.toString());
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = isExtracting || isSaving;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Receipt Bill'),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.document_scanner_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create From Receipt',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: isBusy ? null : _pickReceiptImage,
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
                        height: 190,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: isBusy ? null : _extractWithAi,
                      icon: isExtracting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.auto_awesome),
                      label: Text(
                        isExtracting ? 'Extracting...' : 'Extract with AI',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
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
                  if (_rawResponse != null &&
                      _rawResponse!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      title: const Text('Groq Raw Response'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Text(_rawResponse!),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 28),
                  SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isBusy ? null : _createBill,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: isSaving
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
