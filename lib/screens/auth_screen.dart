import 'package:flutter/material.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Placeholder(),
    );
  }
}

// Widget _buildTextField({required String label, bool obscureText = false}) {
//   return TextField(
//     obscureText: obscureText,
//     decoration: InputDecoration(
//       labelText: label,
//       border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
//       contentPadding: const EdgeInsets.symmetric(
//         horizontal: 16,
//         vertical: 12,
//       ),
//     ),
//   );
// }

// ClipRRect(
// borderRadius: BorderRadius.circular(20),
// child: Image(
// image: AssetImage("assets/Kvizz.png"),
// fit: BoxFit.cover,
// ),
// )
