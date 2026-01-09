import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/auth_screen.dart';
import '../screens/home_page.dart';
import '../screens/splash_screen.dart';
import 'auth_provider.dart';
import 'auth_status.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final status = context.watch<AuthProvider>().status;

    switch (status) {
      case AuthStatus.uninitialized:
      case AuthStatus.checking:
        return SplashScreen();
      case AuthStatus.authenticated:
        return HomeScreen();
      case AuthStatus.expired:
      case AuthStatus.unauthenticated:
        return AuthScreen();
      case AuthStatus.failure:
        return const Scaffold(
          body: Center(child: Text('Authentication failed')),
        );
    }
  }
}
