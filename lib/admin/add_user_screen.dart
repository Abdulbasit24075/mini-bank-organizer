import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/constants/app_colors.dart';
import '../core/services/ledger_service.dart';

class AddUserScreen extends StatefulWidget {
  final String roleToAdd;

  const AddUserScreen({super.key, required this.roleToAdd});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _emailController = TextEditingController();
  bool isLoading = false;

  Future<void> addUser() async {
    if (widget.roleToAdd != 'biller') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Adding admins is restricted.')),
      );
      return;
    }

    final email = _emailController.text.trim();
    if (email.isEmpty) return;

    setState(() => isLoading = true);

    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) {
        throw Exception('User not found');
      }

      final linkedUserData = userQuery.docs.first.data();

      if (linkedUserData['role'] != 'biller') {
        throw Exception('Only users registered as biller can be added.');
      }

      final linkedUserId = userQuery.docs.first.id;
      final adminId = FirebaseAuth.instance.currentUser!.uid;

      // Prevent admin from adding himself as biller
      if (linkedUserId == adminId) {
        throw Exception('You cannot add yourself as a biller.');
      }

      // Check if this biller is already linked with any admin
      final existingRelation = await FirebaseFirestore.instance
          .collection('relationships')
          .where('linkedUserId', isEqualTo: linkedUserId)
          .limit(1)
          .get();

      if (existingRelation.docs.isNotEmpty) {
        throw Exception('This biller is already linked with an admin.');
      }

      await FirebaseFirestore.instance.collection('relationships').add({
        'createdBy': adminId,
        'linkedUserId': linkedUserId,
        'linkedUserRole': 'biller',
        'createdAt': Timestamp.now(),
      });

      await LedgerService().createLedger(
        adminId: adminId,
        billerId: linkedUserId,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Biller added successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.roleToAdd != 'biller') {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          centerTitle: true,
        ),
        body: const Center(
          child: Text('Only billers can be added through this screen.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Add Biller'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 420),
            tween: Tween(begin: 0.96, end: 1),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) => Opacity(
              opacity: value,
              child: Transform.translate(
                offset: Offset(0, 18 * (1 - value)),
                child: child,
              ),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.cardGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'User Email',
                      hintText: 'Enter the registered email of the user',
                      prefixIcon: const Icon(
                        Icons.email,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: addUser,
                            child: const Text('Add Biller'),
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
}
