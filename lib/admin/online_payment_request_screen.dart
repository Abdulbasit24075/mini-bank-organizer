import 'package:flutter/material.dart';

import '../core/services/online_payment_service.dart';

class OnlinePaymentRequestScreen extends StatefulWidget {
  final String adminId;
  final String billerId;
  final String billerName;

  const OnlinePaymentRequestScreen({
    super.key,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  State<OnlinePaymentRequestScreen> createState() =>
      _OnlinePaymentRequestScreenState();
}

class _OnlinePaymentRequestScreenState
    extends State<OnlinePaymentRequestScreen> {
  final _amountCtrl = TextEditingController();
  final _referenceCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _paymentApp;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _referenceCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = int.tryParse(_amountCtrl.text.trim());
    final referenceNumber = _referenceCtrl.text.trim();

    if (_paymentApp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select payment app.')),
      );
      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount.')),
      );
      return;
    }

    if (referenceNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter reference number / transaction ID.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await OnlinePaymentService().createOnlinePaymentRequest(
        adminId: widget.adminId,
        billerId: widget.billerId,
        amount: amount,
        paymentApp: _paymentApp!,
        referenceNumber: referenceNumber,
        note: _noteCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Online payment request sent')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Online Pay'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Biller: ${widget.billerName}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _paymentApp,
                  decoration: const InputDecoration(
                    labelText: 'Payment App',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'JazzCash',
                      child: Text('JazzCash'),
                    ),
                    DropdownMenuItem(
                      value: 'Easypaisa',
                      child: Text('Easypaisa'),
                    ),
                  ],
                  onChanged: (value) => setState(() => _paymentApp = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _referenceCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Reference Number / Transaction ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Note',
                    hintText: 'Optional',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Send Request'),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
