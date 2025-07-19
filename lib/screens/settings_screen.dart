import 'package:flutter/material.dart';
import 'package:kvizz/screens/auth_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final prefs;

  @override
  void initState() {
    initializePreferences();
    super.initState();
  }

  void initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    print("----------Preference initialized in SettingsScreen, isLogin: ${prefs.getBool("isLoggedIn") ?? false}");
  }

  void _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onConfirm();
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: ListView(
              children: [
                // Profile Tab
                Card(
                  margin: const EdgeInsets.all(12),
                  child: ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    title: const Text("Darshan Varu"),
                    subtitle: const Text("darshan@example.com"),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      // TODO: Navigate to Profile Details/Edit screen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => Placeholder()),
                      );
                    },
                  ),
                ),
                const Divider(),

                // Theme Switch
                SwitchListTile(
                  title: const Text("Dark Mode"),
                  secondary: const Icon(Icons.dark_mode),
                  value: themeProvider.isDark,
                  onChanged: (value) {
                    themeProvider.toggleTheme(value);
                  },
                ),
              ],
            ),
          ),

          // Bottom Buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Logout Button - Changed to secondary color
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(
                        context,
                        "Logout",
                        "Are you sure you want to logout?",
                        () {
                          prefs.setBool('isLoggedIn', false);
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()), (route) => false,
                          );
                          print('Logout logic not implemented.');
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSecondary,
                    ),
                    child: const Text("Logout"),
                  ),
                ),
                const SizedBox(height: 10),

                // Delete Account Button - Changed to surface with error text
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      _showConfirmationDialog(
                        context,
                        "Delete Account",
                        "This action is permanent. Are you sure?",
                        () {
                          // TODO: Add delete account logic here
                          // Implement delete account logic here
                          print('Delete account logic not implemented.');
                        },
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: Theme.of(context).colorScheme.error,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.error,
                        width: 2,
                      ),
                    ),
                    child: const Text("Delete Account"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
