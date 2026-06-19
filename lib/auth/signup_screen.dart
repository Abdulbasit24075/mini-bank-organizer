import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../core/constants/app_colors.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String name = '';
  String email = '';
  String password = '';
  String role = 'biller';

  bool isLoading = false;

  void signup() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      await _authService.register(
        name: name,
        email: email,
        password: password,
        role: role,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Signup successful')));

      Navigator.pushReplacementNamed(context, '/login');
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
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 480),
              tween: Tween(begin: 0.94, end: 1),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 24 * (1 - value)),
                  child: Transform.scale(scale: value, child: child),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.cardGradient,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: AppColors.softShadow,
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    const Icon(
                      Icons.account_balance_wallet,
                      size: 80,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Mini Bank Organizer',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: 30),

                    _buildField(
                      label: 'Name',
                      icon: Icons.person,
                      onSaved: (v) => name = v!,
                      validator: (v) => v!.isEmpty ? 'Enter name' : null,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Email',
                      icon: Icons.email,
                      onSaved: (v) => email = v!,
                      validator: (v) => v!.isEmpty ? 'Enter email' : null,
                    ),

                    const SizedBox(height: 16),

                    _buildField(
                      label: 'Password',
                      icon: Icons.lock,
                      obscure: true,
                      onSaved: (v) => password = v!,
                      validator: (v) =>
                          v!.length < 6 ? 'Minimum 6 characters' : null,
                    ),

                    const SizedBox(height: 20),

                    DropdownButtonFormField<String>(
                      initialValue: role,
                      decoration: _inputDecoration(
                        'Select Role',
                        Icons.admin_panel_settings,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                          value: 'biller',
                          child: Text('Biller'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => role = value!);
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: signup,
                              child: const Text(
                                'Create Account',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                    ),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text(
                        'Already have an account? Login',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // 🔧 Helper Widgets

  Widget _buildField({
    required String label,
    required IconData icon,
    bool obscure = false,
    required FormFieldSetter<String> onSaved,
    required FormFieldValidator<String> validator,
  }) {
    return TextFormField(
      obscureText: obscure,
      decoration: _inputDecoration(label, icon),
      validator: validator,
      onSaved: onSaved,
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: AppColors.primary),
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
    );
  }
}
