import 'package:flutter/material.dart';

class AccountDeleteLoadingWidget extends StatefulWidget {
  const AccountDeleteLoadingWidget({super.key});

  @override
  State<AccountDeleteLoadingWidget> createState() => _AccountDeleteLoadingWidgetState();
}

class _AccountDeleteLoadingWidgetState extends State<AccountDeleteLoadingWidget> {
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
                Text("Deleting your account...", style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 8),
                Text('Please wait', style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
