import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../core/services/notebook_service.dart';
import 'notebook_summary_screen.dart';

class NotebookScreen extends StatelessWidget {
  final String ownerId;
  final String ownerRole;
  final String adminId;
  final String billerId;
  final String billerName;

  const NotebookScreen({
    super.key,
    required this.ownerId,
    required this.ownerRole,
    required this.adminId,
    required this.billerId,
    required this.billerName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text('$billerName Notebook'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: NotebookService().notebookStream(
          ownerId: ownerId,
          billerId: billerId,
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = [...snapshot.data!.docs];
          docs.sort((a, b) {
            final aTime = a.data()['createdAt'] as Timestamp?;
            final bTime = b.data()['createdAt'] as Timestamp?;
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;
            return aTime.compareTo(bTime);
          });

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                'No summaries saved yet.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final entry = docs[index].data();
              return _NotebookEntryCard(
                entryId: doc.id,
                entry: entry,
                number: index + 1,
                ownerId: ownerId,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.note_add),
        label: const Text('Create Summary'),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotebookSummaryScreen(
                ownerId: ownerId,
                ownerRole: ownerRole,
                adminId: adminId,
                billerId: billerId,
                billerName: billerName,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _NotebookEntryCard extends StatelessWidget {
  final String entryId;
  final Map<String, dynamic> entry;
  final int number;
  final String ownerId;

  const _NotebookEntryCard({
    required this.entryId,
    required this.entry,
    required this.number,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final int totalBills = _asInt(entry['totalBills']);
    final int totalPaid = _asInt(entry['totalPaid']);
    final int balance = _asInt(entry['balance']);
    final Timestamp? timestamp = entry['createdAt'] as Timestamp?;
    final savedDate = timestamp == null
        ? 'N/A'
        : timestamp.toDate().toString().split('.').first;
    final comment = (entry['comment'] ?? '').toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    '$number',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry['monthDetail'] ?? 'Month Summary',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Saved: $savedDate',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.deepPurple),
                  tooltip: 'Edit',
                  onPressed: () => _showEditSheet(context),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
            const Divider(height: 24),
            _line('Total Bills', 'Rs $totalBills'),
            _line('Total Paid', 'Rs $totalPaid'),
            _line(
              balance >= 0 ? 'Remaining' : 'Advance',
              'Rs ${balance.abs()}',
            ),
            if (comment.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Comment',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(comment),
            ],
          ],
        ),
      ),
    );
  }

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _showEditSheet(BuildContext context) async {
    final monthCtrl = TextEditingController(
      text: (entry['monthDetail'] ?? '').toString(),
    );
    final commentCtrl = TextEditingController(
      text: (entry['comment'] ?? '').toString(),
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        bool isSaving = false;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Record',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: monthCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Month Detail',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: commentCtrl,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Comment',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                        icon: isSaving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: const Text('Save Changes'),
                        onPressed: isSaving
                            ? null
                            : () async {
                                final monthDetail = monthCtrl.text.trim();

                                if (monthDetail.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter month detail.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                setSheetState(() => isSaving = true);

                                try {
                                  await NotebookService().updateEntry(
                                    entryId: entryId,
                                    ownerId: ownerId,
                                    monthDetail: monthDetail,
                                    comment: commentCtrl.text.trim(),
                                  );

                                  if (!context.mounted) return;

                                  FocusScope.of(context).unfocus();
                                  Navigator.pop(sheetContext);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Notebook record updated'),
                                    ),
                                  );
                                } catch (e) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text(e.toString())),
                                  );
                                } finally {
                                  setSheetState(() => isSaving = false);
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Record'),
          content: const Text('Are you sure you want to delete this record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    if (!context.mounted) return;

    try {
      await NotebookService().deleteEntry(entryId: entryId, ownerId: ownerId);

      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notebook record deleted')));
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }
}
