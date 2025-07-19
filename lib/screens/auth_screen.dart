import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // For HomeScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;

  String email = '';
  String password = '';
  String confirmPassword = '';

  void _submit() async {
    final prefs = await SharedPreferences.getInstance();
    print("----------Preference initialized in AuthScreen(), isLoggedIn: ${prefs.getBool("isLoggedIn") ?? false}");

    _formKey.currentState!.save();

    if (!isLogin && password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords don't match")),
      );
      return;
    }

    await prefs.setBool("isLoggedIn", true);
    if (isLogin && (prefs.getBool("isLoggedIn") ?? false)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(isLogin ? 'Logged in!' : 'Signed up!')),
    );

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Card(
            color: cardColor,
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isLogin ? 'Welcome Back' : 'Create an Account',
                      style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Email Field
                    TextFormField(
                      key: const ValueKey('email'),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Password Field
                    TextFormField(
                      key: const ValueKey('password'),
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      onSaved: (value) => password = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password (Signup only)
                    if (!isLogin)
                      TextFormField(
                        key: const ValueKey('confirm_password'),
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        onSaved: (value) => confirmPassword = value ?? '',
                      ),

                    const SizedBox(height: 24),

                    // Submit Button
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        isLogin ? 'Sign In' : 'Sign Up',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Switch Mode
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(
                        isLogin
                            ? "Don't have an account? Sign Up"
                            : "Already have an account? Sign In",
                        style: TextStyle(color: primaryColor),
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
}
