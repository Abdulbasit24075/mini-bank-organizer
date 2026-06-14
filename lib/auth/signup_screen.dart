import 'package:flutter/material.dart';
import 'auth_service.dart';

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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Signup successful')),
      );

      Navigator.pushReplacementNamed(context, '/login');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: const Color(0xFFF3E5F5), // light purple
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title: const Text('Create Account'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),

              const Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 16),

              const Text(
                'Mini Bank Organizer',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
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
                value: role,
                decoration: _inputDecoration(
                  'Select Role',
                  Icons.admin_panel_settings,
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'admin',
                    child: Text('Admin'),
                  ),
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
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: signup,
                  child: const Text(
                    'Create Account',
                    style: TextStyle(fontSize: 16,color: Colors.white),
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
                  style: TextStyle(color: Colors.deepPurple),
                ),
              ),
            ],
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
      prefixIcon: Icon(icon, color: Colors.deepPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.deepPurple),
      ),
    );
  }
}
