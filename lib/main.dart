import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/providers/auth_provider.dart';
import 'package:kvizz/providers/game_session_provider.dart';
import 'package:kvizz/providers/tab_index_provider.dart';
import 'package:kvizz/providers/theme_provider.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:kvizz/screens/app_entry.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "config.env");
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..init()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => TabIndexProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => GameSessionProvider()),
      ],
      child: MyApp(),
    ),
  );
}

/// ---------------- MyApp ------------------
class MyApp extends StatelessWidget {

  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Consumer<AuthProvider>(
      builder: (context, auth, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Kvizz',
          themeMode: themeProvider.themeMode,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          home: AppEntry()
        );
      },
    );
  }
}
