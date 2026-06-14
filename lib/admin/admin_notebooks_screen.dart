import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../core/services/relationship_service.dart';
import '../shared/notebook_screen.dart';

class AdminNotebooksScreen extends StatelessWidget {
  const AdminNotebooksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = RelationshipService();
    final adminId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('My Notebooks'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: service.getLinkedUsersForAdmin(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                textAlign: TextAlign.center,
              ),
            );
          }

          final billers = snapshot.data ?? [];

          if (billers.isEmpty) {
            return const Center(child: Text('No billers added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: billers.length,
            itemBuilder: (context, index) {
              final biller = billers[index];

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    child: Icon(Icons.menu_book, color: Colors.white),
                  ),
                  title: Text(biller['name'] ?? 'Biller'),
                  subtitle: Text(biller['email'] ?? ''),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => NotebookScreen(
                          ownerId: adminId,
                          ownerRole: 'admin',
                          adminId: adminId,
                          billerId: biller['uid'],
                          billerName: biller['name'] ?? 'Biller',
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
