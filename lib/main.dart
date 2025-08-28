import 'package:flutter/material.dart';
import 'package:kvizz/providers/game_session_provider.dart';
import 'package:kvizz/providers/tab_index_provider.dart';
import 'package:kvizz/providers/theme_provider.dart';
import 'package:kvizz/providers/user_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:kvizz/screens/auth_screen.dart';
// import 'package:kvizz/screens/create_or_edit_quiz_screen.dart';
import 'package:kvizz/screens/dashboard_screen.dart';
import 'package:kvizz/screens/my_quiz_screen.dart';
import 'package:kvizz/screens/prompt_screen.dart';
import 'package:kvizz/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import 'package:shared_preferences/shared_preferences.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await dotenv.load(fileName: "config.env");
  runApp(
    MultiProvider(
      providers: [
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

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kvizz',
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: isLoggedIn? const HomeScreen() : const AuthScreen(),
    );
  }
}

/// ---------------- HomeScreen ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Widget> _pages = [
    DashboardScreen(),
    MyQuizzesScreen(),
    PromptScreen(),
    SettingsScreen(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'My Quizzes',
    'Medusa AI',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    final selectedIndexProvider = Provider.of<TabIndexProvider>(context);
    final selectedIndex = selectedIndexProvider.selectedIndex;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[selectedIndex]),
        elevation: 1,
      ),
      body: _pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) {
          selectedIndexProvider.updateSelectedIndex(index);
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'MyQuiz'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'Medusa AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
        selectedItemColor: Color(0xFF4B39EF),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
