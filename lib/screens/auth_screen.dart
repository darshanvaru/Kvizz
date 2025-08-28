import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../api_endpoints.dart';
import '../main.dart';
import '../providers/tab_index_provider.dart';
import '../services/auth_service.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  late final SharedPreferences prefs;

  final _name = TextEditingController();
  final _emailController = TextEditingController();
  final _username = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool isLogin = true;
  bool isLoading = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    initializePreferences();
  }

  void initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  String _getErrorMessage(dynamic error) {
    if (error is SocketException) {
      return "No internet connection. Please check your network and try again.";
    } else if (error.toString().contains('timeout') || error.toString().contains('TimeoutException')) {
      return "Connection timeout. Please check your internet connection and try again.";
    } else if (error.toString().contains('Connection refused')) {
      return "Unable to connect to server. Please try again later.";
    } else if (error.toString().contains('Invalid email or password')) {
      return "Invalid email or password. Please try again";
    } else if (error.toString().contains('FormatException')) {
      return "Server response error. Please try again.";
    } else {
      return "Something went wrong. Please try again.";
    }
  }

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
    setState(() {
      errorMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!isLogin) {
      if (_name.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _username.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        _showErrorDialog('Please fill in all fields!');
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        _showErrorDialog('Passwords do not match!');
        return;
      }
    }

    setState(() {
      isLoading = true;
    });

    try {
      debugPrint("IsLogin: $isLogin");
      if (isLogin) {
        await _performLogin();
      } else {
        await _performSignUp();
      }
    } catch (e) {
      debugPrint('Exception: $e');
      _showErrorDialog(_getErrorMessage(e));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _performLogin() async {
    final email = "${_emailController.text.trim()}@example.com";
    final password = "12345678";
    //final email = _emailController.text.trim();
    //final password = _passwordController.text.trim();

    debugPrint("----------------------");
    debugPrint("Link: ${Uri.parse(ApiEndpoints.login)}");
    debugPrint("Id: $email");
    debugPrint("Password: $password");
    debugPrint("----------------------");

    try {
      final user = await AuthService.login(
        context: context,
        email: email,
        password: password,
      );

      _showSuccessMessage("Login successful! Welcome back, ${user.name}");

      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        Provider.of<TabIndexProvider>(context, listen: false).updateSelectedIndex(0);
      }
    } catch (e) {
      debugPrint("Login Error: $e");
      _showErrorDialog(_getErrorMessage(e));
    }
  }

  Future<void> _performSignUp() async {
    final name = _name.text.trim();
    final username = _username.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final passwordConfirm = _confirmPasswordController.text.trim();

    debugPrint("----------------------");
    debugPrint("Link: ${Uri.parse(ApiEndpoints.signup)}");
    debugPrint("Name: $name");
    debugPrint("Username: $username");
    debugPrint("Email: $email");
    debugPrint("Password: $password");
    debugPrint("Password Confirm: $passwordConfirm");
    debugPrint("----------------------");

    try {
      await AuthService.signup(
        name: name,
        username: username,
        email: email,
        password: password,
        passwordConfirm: passwordConfirm,
      );

      _showSuccessMessage("Account created successfully! Please login.");
      setState(() {
        isLogin = true;
        _passwordController.clear();
        _confirmPasswordController.clear();
      });
    } catch (e) {
      debugPrint("Signup Error: $e");
      _showErrorDialog(_getErrorMessage(e));
    }
  }

  Widget _buildLoginInFields() {
    return Column(
      key: const ValueKey('signIn'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
          // validator: (value) {
          //   if (value == null || value.isEmpty) {
          //     return 'Please enter your password';
          //   }
          //   return null;
          // },
        ),
      ],
    );
  }

  Widget _buildSignUpFields() {
    return Column(
      key: const ValueKey('signUp'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: _name,
          enabled: !isLoading,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
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
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a username';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
            if (value == null || value.length < 6) {
              return 'Password must be at least 6 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
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
            if (value != _passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
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
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AnimatedSize(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: Card(
                  color: cardColor,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isLogin ? 'Welcome Back' : 'Create an Account',
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
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
                                  Icon(
                                    Icons.error_outline,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorMessage!,
                                      style: TextStyle(
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // Animate the form fields
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.05),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: isLogin
                                ? _buildLoginInFields()
                                : _buildSignUpFields(),
                          ),
                          const SizedBox(height: 24),
                          // Submit button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 36,
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                backgroundColor: primaryColor,
                              ),
                              child: isLoading
                                  ? Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor: AlwaysStoppedAnimation(
                                              Colors.white,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          isLogin
                                              ? 'Signing In...'
                                              : 'Creating Account...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      isLogin ? 'Sign In' : 'Sign Up',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Toggle
                          TextButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    setState(() {
                                      isLogin = !isLogin;
                                      errorMessage = null;
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
          ),
          // Screen-wide loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
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
                          isLogin
                              ? 'Signing you in...'
                              : 'Creating your account...',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Please wait',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
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
