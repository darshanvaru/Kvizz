import 'package:flutter/material.dart';
import 'package:kvizz/services/user_service.dart';
import 'package:kvizz/utils/status_message_widgets.dart';


class ForgetPasswordScreen extends StatefulWidget {
  const ForgetPasswordScreen({super.key});

  @override
  State<ForgetPasswordScreen> createState() => _ForgetPasswordScreenState();
}

class _ForgetPasswordScreenState extends State<ForgetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController tokenController = TextEditingController();
  final TextEditingController newPwdController = TextEditingController();
  final TextEditingController confirmPwdController = TextEditingController();

  bool _isLoading = false;
  bool isCodeSent = false;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  String? _errorText;

  void handleEmailSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isLoading = true);

    try {
      final success = await UserService().forgetPassword(emailController.text);


      if (success) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Code sent to your email address')),
          );
        }

        setState(() {
          isCodeSent = true;
          _isLoading = false;
          _errorText = "";
        });
      } else {
        setState(() {
          _errorText = "Enter valid email address";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Something went wrong, Please try again!";
        _isLoading = false;
      });
    }
  }

  void handleCodeSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await UserService().resetPassword(tokenController.text, newPwdController.text, confirmPwdController.text);

      if (success) {
        if(mounted) {
          Navigator.pop(context);
          showSuccessMessage(context: context, message: "Password reset successfully!");
        }

        setState(() {
          isCodeSent = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorText = "Token is Expired or invalid";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorText = "Something went wrong, Please try again!";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Forget Password")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AnimatedSize(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: Card(
              color: Theme.of(context).cardColor,
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      if (_errorText != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Text(
                            _errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),

                      if (!isCodeSent)...{
                        TextFormField(
                          controller: emailController,
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
                        SizedBox(height: 15),
                        Text(
                          "A Reset code will be sent to this Email ID and will need to reset the password",
                          style: TextStyle(color: Colors.black54),
                        ),
                      },

                      if (isCodeSent) ...{
                        TextFormField(
                          controller: tokenController,
                          decoration: InputDecoration(
                            labelText: 'Reset Code',
                            prefixIcon: Icon(Icons.code),
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter Reset Code';
                            if (value.length != 8) return "Enter 8 digit code";
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 16),

                        TextFormField(
                          controller: newPwdController,
                          obscureText: obscureNewPassword,
                          decoration: InputDecoration(
                            labelText: 'New Password',
                            prefixIcon: Icon(Icons.password),
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureNewPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureNewPassword = !obscureNewPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter new password';
                            if (value.length < 8) return 'Password must be at least 8 characters';
                            return null;
                          },
                          textInputAction: TextInputAction.next,
                          onFieldSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        SizedBox(height: 16),

                        TextFormField(
                          controller: confirmPwdController,
                          obscureText: obscureConfirmPassword,
                          decoration: InputDecoration(
                            labelText: 'Confirm New Password',
                            prefixIcon: Icon(Icons.password),
                            border: OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  obscureConfirmPassword =
                                      !obscureConfirmPassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Confirm new password';
                            if (value != newPwdController.text) return 'Passwords do not match';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => handleCodeSubmit(),
                        ),
                      },
                      const SizedBox(height: 30),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : isCodeSent ? handleCodeSubmit : handleEmailSubmit,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 36,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                          ),
                          child: _isLoading
                              ? Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                        width: 30,
                                        height: 30,
                                        child: const CircularProgressIndicator(color: Colors.white)
                                    ),
                                    SizedBox(width: 10,),
                                    Text(isCodeSent ? "Updating..." : "Sending...",
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Theme.of(context).colorScheme.onPrimary,
                                        )
                                    )
                                  ],
                                )
                              : Text(
                                isCodeSent ? "Update Password" : "Send Code",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.onPrimary),
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
    );
  }
}
