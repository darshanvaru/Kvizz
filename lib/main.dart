import 'package:flutter/material.dart';
import 'package:kvizz/providers/theme_provider.dart';
import 'package:kvizz/screens/create_or_edit_quiz_screen.dart';
import 'package:kvizz/screens/dashboard_screen.dart';
import 'package:kvizz/screens/my_quiz.dart';
import 'package:kvizz/screens/prompt_screen.dart';
import 'package:kvizz/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:provider/provider.dart';
// import 'package:kvizz/screens/auth_screen.dart';
import 'package:kvizz/screens/ongoing_quiz_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

// ---------------- MyApp ------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kwizz',
      // theme: quizAppTheme,
      themeMode: themeProvider.themeMode,
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}

// ---------------- HomeScreen ------------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    DashboardScreen(),
    MyQuizzesScreen(),
    PromptScreen(),
    SettingsScreen()
    ,
  ];

  final List<String> _titles = [
    'Dashboard',
    'My Quizzes',
    'Medusa AI',
    'Settings',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        elevation: 1,
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
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
