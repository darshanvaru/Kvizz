import 'package:flutter/material.dart';
import 'package:kvizz/screens/prompt_screen.dart';
import 'package:kvizz/screens/settings_screen.dart';
import 'package:provider/provider.dart';

import '../providers/tab_index_provider.dart';
import 'dashboard_screen.dart';
import 'my_quiz_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  static const List<Widget> _pages = [
    DashboardScreen(),
    MyQuizzesScreen(),
    PromptScreen(),
    SettingsScreen(),
  ];

  static const List<String> _titles = [
    'Dashboard',
    'My Quizzes',
    'Medusa AI',
    'Settings',
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<TabIndexProvider>(
      builder: (context, tabProvider, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(_titles[tabProvider.selectedIndex]),
            elevation: 1,
          ),
          body: _pages[tabProvider.selectedIndex],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: tabProvider.selectedIndex,
            onTap: (index) {
              Provider.of<TabIndexProvider>(context, listen: false).updateSelectedIndex(index);
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'MyQuiz'),
              BottomNavigationBarItem(
                icon: Icon(Icons.smart_toy),
                label: 'Medusa AI',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: 'Settings',
              ),
            ],
            selectedItemColor: const Color(0xFF4B39EF),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
          ),
        );
      },
    );
  }
}