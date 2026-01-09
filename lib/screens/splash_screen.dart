import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 10,),
            Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
