import 'package:flutter/material.dart';
import 'package:kvizz/providers/auth.dart';
import 'package:kvizz/providers/game_session_provider.dart';
import 'package:kvizz/providers/tab_index_provider.dart';
import 'package:kvizz/providers/theme_provider.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/screens/auth_screen.dart';
import 'package:kvizz/screens/home_page.dart';
import 'package:kvizz/screens/splash_screen.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

import 'models/user_model.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await dotenv.load(fileName: "config.env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => Auth()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TabIndexProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GameSessionProvider()),
      ],
      child: MyApp(isLoggedIn: prefs.getBool("isLoggedIn") ?? false),
    ),
  );
}

/// ---------------- MyApp ------------------
class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    debugPrint("IsLoggedIn: $isLoggedIn");

    // TODO: AutoLogin
    // autoLogin? HomeScreen : AuthScreen
    // autoLogin will login using user's saved id and password from storage and tries to login, if login fails because of JWT then it will return false

    return Consumer<Auth>(
      builder: (context, auth, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kvizz',
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
            home: Consumer<Auth>(
              builder: (context, auth, child) {
                return FutureBuilder<UserModel?>(
                  future: auth.tryAutoLogin(),
                  builder: (ctx, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SplashScreen();
                    } else {
                      if (snapshot.hasData && snapshot.data != null) {
                        Provider.of<UserProvider>(ctx, listen: false).setCurrentUserWithoutNotifying(snapshot.data!);
                        return HomeScreen();
                      } else {
                        return AuthScreen();
                      }
                    }
                  },
                );
              },
            )
        );
      },
    );
  }
}
