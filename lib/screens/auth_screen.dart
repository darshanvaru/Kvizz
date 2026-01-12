import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

import '../api_endpoints.dart';
import '../providers/auth_provider.dart';
import '../providers/tab_index_provider.dart';
import '../utils/status_message_widgets.dart';
import '../widgets/auth_loading_widget.dart';

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

  @override
  void initState() {
    super.initState();
    initializePreferences();
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

  void initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
  }

  /// General Errors
  // No internet connection
  // Connection timeout. Please try again.
  // Unable to connect to server. Please try again later.
  // Something went wrong. Please try again.

  /// Login Errors
  // Email or Password incorrect

  /// Signup Errors
  // Email already in use
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('timeout') || errorStr.contains('time out')) {
      return "Connection timeout. Please check your internet connection and try again.";
    } else if (errorStr.contains('no internet connection')) {
      return "No internet connection. Please check your network and try again.";
    } else if (errorStr.contains('server error')) {
      return "Unable to connect to server. Please try again later.";
    } else if (errorStr.contains("email or password incorrect")) {
      return "Invalid credentials. Please try again.";
    } else if (errorStr.contains("email already in use")) {
      return "Email already in use. Please try a different email.";
    } else if (errorStr.contains("Something went wrong. Please try again.")) {
      return "Something went wrong. Please try again.";
    } else {
      return "Raw Error: ${error.toString()}";
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Empty text fields warning
    if (!isLogin) {
      if (_name.text.trim().isEmpty ||
          _emailController.text.trim().isEmpty ||
          _username.text.trim().isEmpty ||
          _passwordController.text.trim().isEmpty ||
          _confirmPasswordController.text.trim().isEmpty) {
        showErrorDialog(message: 'Please fill in all fields!', context: context);
        return;
      }
      if (_passwordController.text != _confirmPasswordController.text) {
        showErrorDialog(message: 'Passwords do not match!', context: context);
        return;
      }
    }
    else {
      // if (_emailController.text.trim().isEmpty ||
      //     _passwordController.text.trim().isEmpty) {
      //   showErrorDialog(message: 'Please fill in all fields!', context: context);
      //   return;
      // }
    }

    setState(() {
      isLoading = true;
    });

    try {
      if (isLogin) {
        await _login();
      } else {
        await _signUp();
      }
    } catch (e) {
      debugPrint('Exception from AuthScreen: $e');
      showErrorDialog(message: _getErrorMessage(e), context: context);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _login() async {
    final email = "${_emailController.text.trim()}@example.com";
    final password = "12345678";
    // final email = _emailController.text.trim();
    // final password = _passwordController.text.trim();

    debugPrint("----------------------");
    debugPrint("Link: ${Uri.parse(ApiEndpoints.login)}");
    debugPrint("Id: $email");
    debugPrint("Password: $password");
    debugPrint("----------------------");

    try {
      final user = await context.read<AuthProvider>().login(
        context: context,
        email: email,
        password: password,
      );

      print("Login Success");
      showSuccessMessage(message: "Login successful! Welcome back, ${user.name}", context: context);
      Provider.of<TabIndexProvider>(context, listen: false).updateSelectedIndex(0);
    } catch (e) {
      print("Login Failure");
      debugPrint("Login Error: $e");
      throw Exception(e);
    }
  }

  Future<void> _signUp() async {
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
      await context.read<AuthProvider>().signup(
          name: name,
          username: username,
          email: email,
          password: password,
          passwordConfirm: passwordConfirm
      );
      showSuccessMessage(message: "Account created successfully! Please login.", context: context);
      setState(() {
        isLogin = true;
        _confirmPasswordController.clear();
      });
    } catch (e) {
      debugPrint("Signup Error: $e");
      throw Exception(e);
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
                                            valueColor: AlwaysStoppedAnimation(Theme.of(context).colorScheme.onPrimary),
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text(
                                          isLogin
                                              ? 'Signing In...'
                                              : 'Creating Account...',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Theme.of(context).colorScheme.onPrimary,
                                          ),
                                        ),
                                      ],
                                    )
                                  : Text(
                                      isLogin ? 'Sign In' : 'Sign Up',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onPrimary,
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
            AuthLoadingWidget(isLogin: isLogin,),
        ],
      ),
    );
  }
}
