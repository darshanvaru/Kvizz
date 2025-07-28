import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../api_endpoints.dart';
import '../main.dart';
import '../models/UserModel.dart';
import '../providers/user_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({Key? key}) : super(key: key);

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final SharedPreferences prefs;
  final _name = TextEditingController();
  final _emailController = TextEditingController();
  final _username = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool isLoading = false; // Added loading state
  String? errorMessage; // Added error message state

  @override
  void initState() {
    initializePreferences();
    super.initState();
  }

  void initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  // Enhanced error handling with user-friendly messages
  String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return "No internet connection. Please check your network and try again.";
    } else if (error.toString().contains('timeout') ||
        error.toString().contains('TimeoutException')) {
      return "Connection timeout. Please check your internet connection and try again.";
    } else if (error.toString().contains('Connection refused')) {
      return "Unable to connect to server. Please try again later.";
    } else if (error.toString().contains('FormatException')) {
      return "Server response error. Please try again.";
    } else {
      return "Something went wrong. Please try again.";
    }
  }

  // Show error dialog
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text('Error'),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success message
  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _submit() async {
    // Clear previous error message
    setState(() {
      errorMessage = null;
    });

    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Check required fields
    if (isLogin) {
      if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
        _showErrorDialog('Please enter both email and password!');
        return;
      }
    } else {
      if (_name.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _username.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        _showErrorDialog('Please fill in all fields!');
        return;
      }

      // Check password match
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog('Passwords do not match!');
        return;
      }
    }

    // Start loading
    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        await _performLogin();
      } else {
        await _performSignUp();
      }
    } catch (e) {
      print('Exception: $e');
      _showErrorDialog(_getErrorMessage(e));
    } finally {
      // Stop loading
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _performLogin() async {
    final Map<String, dynamic> data = {
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.login),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 30), // 30 second timeout
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print("Login Status code: ${response.statusCode}");
      print("Login Response body: '${response.body}'");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == "success") {
          // Save JWT
          await prefs.setString("jwt", decoded["token"]);
          // Parse user model
          final user = UserModel.fromJson(decoded["user"]);
          // Save to provider
          Provider.of<UserProvider>(context, listen: false).setUser(user);

          _showSuccessMessage("Login successful! Welcome back, ${user.name}");

          // Navigate to Home with delay to show success message
          await Future.delayed(Duration(milliseconds: 1500));
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          }
        } else {
          throw Exception(decoded["message"] ?? "Login failed");
        }
      } else if (response.statusCode == 401) {
        throw Exception("Invalid email or password");
      } else if (response.statusCode >= 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Login failed. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }

  Future<void> _performSignUp() async {
    final Map<String, dynamic> data = {
      "_id": DateTime.now().millisecondsSinceEpoch.toString(),
      "name": _name.text.trim(),
      "username": _username.text.trim(),
      "email": _emailController.text.trim(),
      "password": _passwordController.text.trim(),
      "passwordConfirm": _confirmPasswordController.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.signup),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(data),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Connection timeout. Please try again.');
        },
      );

      print("SignUp Status code: ${response.statusCode}");
      print("SignUp Response body: '${response.body}'");

      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == "success") {
          _showSuccessMessage("Account created successfully! Please login.");

          // Switch to login mode
          setState(() {
            isLogin = true;
            _passwordController.clear();
            _confirmPasswordController.clear();
          });
        } else {
          throw Exception(decoded["message"] ?? "Registration failed");
        }
      } else if (response.statusCode == 409) {
        throw Exception("Email or username already exists");
      } else if (response.statusCode >= 500) {
        throw Exception("Server error. Please try again later.");
      } else {
        throw Exception("Registration failed. Please try again.");
      }
    } on SocketException {
      throw Exception("No internet connection");
    } on http.ClientException {
      throw Exception("Connection error. Please check your internet connection.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textTheme = theme.textTheme;
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Stack(
        children: [
          Center(
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
                        // Header with loading indicator
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isLogin ? 'Welcome Back' : 'Create an Account',
                              style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            if (isLoading) ...[
                              SizedBox(width: 16),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Error message display
                        if (errorMessage != null) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red.shade200),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 20),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    errorMessage!,
                                    style: TextStyle(color: Colors.red.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Form fields
                        if (!isLogin) ...[
                          TextFormField(
                            controller: _name,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!isLogin && (value == null || value.trim().isEmpty)) {
                                return 'Please enter your name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _username,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.alternate_email),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (!isLogin && (value == null || value.trim().isEmpty)) {
                                return 'Please enter a username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _emailController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: _passwordController,
                          enabled: !isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            prefixIcon: Icon(Icons.lock),
                            border: OutlineInputBorder(),
                          ),
                          obscureText: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (!isLogin && value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        if (!isLogin) ...[
                          TextFormField(
                            controller: _confirmPasswordController,
                            enabled: !isLoading,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              prefixIcon: Icon(Icons.lock_outline),
                              border: OutlineInputBorder(),
                            ),
                            obscureText: true,
                            validator: (value) {
                              if (!isLogin && value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        const SizedBox(height: 8),

                        // Submit button with loading state
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: primaryColor,
                            ),
                            child: isLoading
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  isLogin ? 'Signing In...' : 'Creating Account...',
                                  style: TextStyle(fontSize: 16, color: Colors.white),
                                ),
                              ],
                            )
                                : Text(
                              isLogin ? 'Sign In' : 'Sign Up',
                              style: const TextStyle(fontSize: 16, color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Toggle button
                        TextButton(
                          onPressed: isLoading ? null : () {
                            setState(() {
                              isLogin = !isLogin;
                              errorMessage = null;
                              // Clear form when switching
                              _formKey.currentState?.reset();
                            });
                          },
                          child: Text(
                            isLogin
                                ? "Don't have an account? Sign Up"
                                : "Already have an account? Sign In",
                            style: TextStyle(
                              color: isLoading ? Colors.grey : primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Full screen loading overlay (optional, for critical operations)
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          isLogin ? 'Signing you in...' : 'Creating your account...',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait',
                          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _emailController.dispose();
    _username.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
