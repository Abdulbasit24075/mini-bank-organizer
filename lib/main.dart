import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'auth/signup_screen.dart';
import 'auth/login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mini Bank Organizer',
      theme: ThemeData(
        primarySwatch: Colors.blue, scaffoldBackgroundColor: Colors.pink.shade200
      ),

      // 🔹 TEMPORARY ENTRY POINT
      home: const SignupScreen(),

      // 🔹 OPTIONAL: named routes (useful later)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
      },
    );
  }
}
