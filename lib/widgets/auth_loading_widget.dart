import 'package:flutter/material.dart';

class AuthLoadingWidget extends StatefulWidget {
  final bool isLogin;

  const AuthLoadingWidget({super.key, required this.isLogin});

  @override
  State<AuthLoadingWidget> createState() => _AuthLoadingWidgetState();
}

class _AuthLoadingWidgetState extends State<AuthLoadingWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
                  widget.isLogin
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
    );
  }
}
