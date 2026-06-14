import 'package:flutter/material.dart';

import '../core/services/notebook_service.dart';

class NotebookSummaryScreen extends StatefulWidget {
  final String ownerId;
  final String ownerRole;
  final String adminId;
  final String billerId;
  final String billerName;

  const NotebookSummaryScreen({
    super.key,
    required this.ownerId,
    required this.ownerRole,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  State<NotebookSummaryScreen> createState() => _NotebookSummaryScreenState();
}

class _NotebookSummaryScreenState extends State<NotebookSummaryScreen> {
  final _monthCtrl = TextEditingController();
  final _commentCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _monthCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveSummary() async {
    final monthDetail = _monthCtrl.text.trim();

    if (monthDetail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter month detail.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await NotebookService().createSummary(
        ownerId: widget.ownerId,
        ownerRole: widget.ownerRole,
        adminId: widget.adminId,
        billerId: widget.billerId,
        billerName: widget.billerName,
        monthDetail: monthDetail,
        comment: _commentCtrl.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Summary saved in notebook')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Create Summary'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.billerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will save the current total bills, total paid, and remaining or advance amount.',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _monthCtrl,
              decoration: InputDecoration(
                labelText: 'Month Detail',
                hintText: 'Example: January 2026',
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Comment',
                hintText: 'Optional note',
                alignLabelWithHint: true,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Save Summary'),
                onPressed: _isSaving ? null : _saveSummary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
