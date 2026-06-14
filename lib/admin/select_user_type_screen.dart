import 'package:flutter/material.dart';
import 'add_user_screen.dart';

class SelectUserTypeScreen extends StatelessWidget {
  const SelectUserTypeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add User'),
        backgroundColor: Colors.deepPurple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 40),

            // "Add Admin" option removed from here

            _optionCard(
              context,
              title: 'Add Biller',
              icon: Icons.person_add,
              role: 'biller',
            ),
          ],
        ),
      ),
    );
  }

  Widget _optionCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required String role,
      }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AddUserScreen(roleToAdd: role),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.deepPurple),
              const SizedBox(width: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}