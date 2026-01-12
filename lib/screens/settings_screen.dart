import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kvizz/screens/profile_page_screen.dart';
import 'package:kvizz/screens/update_password_screen.dart';
import 'package:kvizz/services/socket_service.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../providers/user_provider.dart';
import '../services/user_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final SharedPreferences prefs;
  bool isLoading = false;

  @override
  void initState() {
    initializePreferences();
    if(Provider.of<UserProvider>(context, listen: false).currentUser == null) {
      _loadUserData();
    }
    super.initState();
  }

  Future _loadUserData() async {
    setState(() => isLoading = true);
    try {
      final fetchedUser = await UserService().fetchUserProfile();

      debugPrint('DEBUG: Loaded user name: ${fetchedUser.name}');
      debugPrint('DEBUG: Loaded user username: ${fetchedUser.username}');
      debugPrint('DEBUG: Loaded user photo: ${fetchedUser.photo}');

      if(mounted) {
        Provider.of<UserProvider>(context, listen: false).setCurrentUser(fetchedUser);
      }
      setState(() => isLoading = false);

    } catch (e) {
      debugPrint('DEBUG: Exception caught in _loadUserData(): $e');
    }
  }

  void initializePreferences() async {
    prefs = await SharedPreferences.getInstance();
    debugPrint("----------Preference initialized in SettingsScreen, isLogin: ${prefs.getBool("isLoggedIn") ?? false}");
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
    final currentUser = Provider.of<UserProvider>(context, listen: true).currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: ListView(
                children: [

                  // Profile Tab (Need Photo, Name, Username)
                  Card(
                    margin: const EdgeInsets.all(12),
                    child: ListTile(
                      leading: Container(
                        decoration: const BoxDecoration(
                          color: Colors.black26,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: SvgPicture.network(
                            currentUser!.photo!,
                            placeholderBuilder: (context) =>
                            const CircularProgressIndicator(),
                            height: 80.0,
                            width: 50.0,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      title: Text(currentUser.name),
                      subtitle: Text(currentUser.email),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // Navigate to Profile Details/Edit screen
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ProfileScreen()),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  //General Settings
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: const Text(
                      'General Settings',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Theme Switch
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.brightness_6, color: Colors.blueAccent),
                      title: const Text("Select Theme"),
                      trailing: Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: DropdownButton<ThemeMode>(
                          value: themeProvider.themeMode,
                          isExpanded: false,
                          borderRadius: BorderRadius.circular(12),
                          dropdownColor: Theme.of(context).cardColor,
                          items: const [
                            DropdownMenuItem(
                              value: ThemeMode.system,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text("System"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.light,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text("Light"),
                              ),
                            ),
                            DropdownMenuItem(
                              value: ThemeMode.dark,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                child: Text("Dark"),
                              ),
                            ),
                          ],
                          underline: const SizedBox(),
                          onChanged: (ThemeMode? mode) {
                            themeProvider.toggleTheme(mode ?? ThemeMode.light);
                          },
                        ),
                      ),
                    ),
                  ),

                  // Update Password Button
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.update, color: Colors.blueAccent),
                      title: const Text("Update Password"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => UpdatePasswordScreen())
                        );
                      },
                    ),
                  ),

                  // Forgot Password Button
                  Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    child: ListTile(
                      leading: const Icon(Icons.lock_reset, color: Colors.blueAccent),
                      title: const Text("Forget Password"),
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        // TODO: Add forgot password logic or navigation
                        // Navigator.push(
                        //   context,
                        //   MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        // );
                        debugPrint('Forget Password logic not implemented.');
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(
                          context,
                          "Logout",
                          "Are you sure you want to logout?",
                              () {
                            SocketService().manualDisconnect();
                            prefs.setBool('isLoggedIn', false);
                            prefs.setString('jwt', "");
                            Provider.of<AuthProvider>(context, listen: false).logout();
                            // Navigator.pushAndRemoveUntil(
                            //   context,
                            //   MaterialPageRoute(
                            //       builder: (context) => const AuthScreen()),
                            //       (route) => false,
                            // );
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                      child: const Text("Logout"),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Delete Account Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(
                          context,
                          "Delete Account",
                          "This action is permanent. Are you sure?",
                              () {
                            // TODO: Add delete account logic
                            debugPrint('Delete account logic not implemented.');
                          },
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        Theme.of(context).colorScheme.surface,
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
      ),
    );

  }
}
