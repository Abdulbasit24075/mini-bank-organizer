import 'package:flutter/material.dart';
import 'auth_service.dart';
import '../core/services/user_service.dart';
import '../admin/admin_dashboard.dart';
import '../biller/biller_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  String email = '';
  String password = '';
  bool isLoading = false;

  void login() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();
    setState(() => isLoading = true);

    try {
      await _authService.login(
        email: email,
        password: password,
      );

      final userService = UserService();
      final role = await userService.getCurrentUserRole();

      if (!mounted) return;

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const AdminDashboard(),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const BillerDashboard(),
          ),
        );
      }
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
        title: const Text('Welcome Back'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 30),

              const Icon(
                Icons.lock_open_rounded,
                size: 80,
                color: Colors.deepPurple,
              ),

              const SizedBox(height: 12),

              const Text(
                'Login to your account',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),

              const SizedBox(height: 30),

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
                validator: (v) => v!.isEmpty ? 'Enter password' : null,
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
                  onPressed: login,
                  child: const Text(
                    'Login',
                    style: TextStyle(fontSize: 16,color: Colors.white),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              TextButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/signup');
                },
                child: const Text(
                  "Don't have an account? Sign up",
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
