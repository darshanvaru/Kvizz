import 'package:flutter/cupertino.dart';
import 'package:kvizz/main.dart';
import 'package:kvizz/screens/auth_screen.dart';
import 'package:provider/provider.dart';

import '../enums/enums.dart';
import '../providers/auth_provider.dart';
import 'home_page.dart';

class AppEntry extends StatelessWidget {
  const AppEntry({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthProvider>().state;

    switch (authState) {
      case AuthStatus.checking:
        return SplashScreen();

      case AuthStatus.unauthenticated:
      case AuthStatus.expired:
        return const AuthScreen();

      case AuthStatus.authenticated:
        return const HomeScreen();
    }
  }
}
