import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import '../models/user_model.dart';
import '../providers/tab_index_provider.dart';
import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final SharedPreferences prefs;
  final api = "http://192.168.104.75:8000/api/v1/users";
  final _name = TextEditingController();
  final _emailController = TextEditingController();
  final _username = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isLogin = true;
  bool isLoading = false;


  String email = '';
  String password = '';
  String confirmPassword = '';
  String name = '';

  @override
  void initState() {
    initializePreferences();
    super.initState();
  }

  void initializePreferences() async {
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    setState(() {
      prefs = preferences;
    });
  }


  void _submit() async {
    if (isLoading) return;

    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        // Login
        if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
          _showError("Please enter both email and password!");
          return;
        }

        final apiUrl = Uri.parse("$api/login");
        final Map<String, String> data = {
          "email": _emailController.text,
          "password": _passwordController.text,
        };

        final response = await http.post(
          apiUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded["status"] == "success") {
            prefs.setString("jwt", decoded["token"]);
            final user = UserModel.fromJson(decoded["user"]);
            Provider.of<UserProvider>(context, listen: false).setUser(user);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            _showError(decoded["message"] ?? "Login failed.");
          }
        } else {
          _showError("Invalid response (${response.statusCode})");
        }
      } else {
        // Signup
        if (_name.text.isEmpty ||
            _emailController.text.isEmpty ||
            _username.text.isEmpty ||
            _passwordController.text.isEmpty ||
            _confirmPasswordController.text.isEmpty) {
          _showError("Please fill all the fields.");
          return;
        }

        if (_passwordController.text != _confirmPasswordController.text) {
          _showError("Passwords do not match.");
          return;
        }

        final apiUrl = Uri.parse("$api/signup");
        final Map<String, String> data = {
          "_id": DateTime.now().millisecondsSinceEpoch.toString(),
          "name": _name.text,
          "username": _username.text,
          "email": _emailController.text,
          "password": _passwordController.text,
          "passwordConfirm": _confirmPasswordController.text,
        };

        final response = await http.post(
          apiUrl,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(data),
        );

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          if (decoded["status"] == "success") {
            setState(() {
              isLogin = true;
            });
            Provider.of<SelectedIndexProvider>(context, listen: false)
                .updateSelectedIndex(0);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          } else {
            _showError(decoded["message"] ?? "Signup failed.");
          }
        } else {
          _showError("Signup failed: ${response.statusCode}");
        }
      }
    } catch (e, stack) {
      _showError("An error occurred: $e");
      print("Error: $e");
      print(stack);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showError(String message) {
    setState(() {
      isLoading = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
      ),
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

                    if (!isLogin)
                      TextFormField(
                        controller: _name,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        // onSaved: (value) => name = value ?? '',
                      ),
                    const SizedBox(height: 16),

                    if (!isLogin)
                      TextFormField(
                        controller: _username,
                        decoration: const InputDecoration(
                          labelText: 'User Name',
                          prefixIcon: Icon(Icons.person),
                        ),
                        // onSaved: (value) => username = value ?? '',
                      ),
                    const SizedBox(height: 16),

                    TextFormField(
                      key: const ValueKey('email'),
                      controller: _emailController,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      onSaved: (value) => email = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      key: const ValueKey('password'),
                      controller: _passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        prefixIcon: Icon(Icons.lock),
                      ),
                      obscureText: true,
                      onSaved: (value) => password = value ?? '',
                    ),
                    const SizedBox(height: 16),

                    if (!isLogin)
                      TextFormField(
                        key: const ValueKey('confirm_password'),
                        controller: _confirmPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                        obscureText: true,
                        onSaved: (value) => confirmPassword = value ?? '',
                      ),

                    const SizedBox(height: 24),

                    isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
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
