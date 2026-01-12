import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';

import '../models/user_model.dart';
import '../providers/user_provider.dart';
import '../services/user_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  ProfileScreenState createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  UserModel? user;
  bool _isUpdating = false;
  bool _loading = true;
  bool isEditing = false;
  String? _error;

  late TextEditingController _nameController;
  late TextEditingController _mobileController;
  late TextEditingController _usernameController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if(Provider.of<UserProvider>(context, listen: false).currentUser == null) {
      _loadUserData();
    }
  }

  Future _loadUserData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final fetchedUser = await UserService().fetchUserProfile();
      
      debugPrint('DEBUG: Loaded user name: ${fetchedUser.name}');
      debugPrint('DEBUG: Loaded user username: ${fetchedUser.username}');
      debugPrint('DEBUG: Loaded user photo: ${fetchedUser.photo}');
      
      if(mounted) {
        Provider.of<UserProvider>(context, listen: false).setCurrentUser(fetchedUser);
      }
      
      _nameController = TextEditingController(text: fetchedUser.name);
      _mobileController = TextEditingController(text: fetchedUser.mobile);
      _usernameController = TextEditingController(text: fetchedUser.username);
      
      setState(() {
        user = fetchedUser;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('DEBUG: Exception caught in _loadUserData(): $e');
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(child: Text('Error: $_error',
          style: theme.textTheme.bodyMedium,
        )),
      );
    }

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('No user data available', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 230,
            pinned: true,
            iconTheme: IconThemeData(color: Colors.black),
            backgroundColor: Theme.of(context).colorScheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildProfileAvatar(user!, theme),
                    const SizedBox(height: 12),
                    Text(
                      user!.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                    if (user!.username != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '@${user!.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (user!.stats != null) _buildQuickStats(user!.stats!, theme),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _buildSectionTitle('Personal Information', theme),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () => setState(() => isEditing = !isEditing),
                        icon: Icon(isEditing ? Icons.cancel : Icons.edit),
                        label: Text(isEditing ? "Cancel" : "Edit"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  isEditing ? _buildEditablePersonalInfoCard(user!, theme) : _buildPersonalInfoCard(user!, theme),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Account Information', theme),
                  const SizedBox(height: 12),
                  _buildAccountInfoCard(user!, theme),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Quiz Activity', theme),
                  const SizedBox(height: 12),
                  _buildQuizActivityCard(user!, theme),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(UserModel user, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            offset: const Offset(0, 4),
          ),
        ],
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: SvgPicture.network(
          user.photo ?? '',
          placeholderBuilder: (context) => const CircularProgressIndicator(),
          height: 100.0,
          width: 100.0,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildQuickStats(UserStats stats, ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Games Played',
            stats.gamesPlayed.toString(),
            Icons.quiz,
            theme.colorScheme.secondary,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Score',
            stats.totalScore.toString(),
            Icons.star,
            Colors.amber,
            theme,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Average Score',
            '${stats.averageScore.toStringAsFixed(1)}%',
            Icons.trending_up,
            Colors.green,
            theme,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return SizedBox(
      height: 152,
      child: Card(
        // color: theme.cardColor,
        elevation: 4,  // adjust elevation for shadow effect
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    )
    ;
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildEditablePersonalInfoCard(UserModel user, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textInputAction: TextInputAction.next,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Name cannot be empty' : null,
              ),
              const SizedBox(height: 10),
              // Username field
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
                textInputAction: TextInputAction.next,
                validator: (val) => (val == null || val.trim().isEmpty) ? 'Username cannot be empty' : null,
              ),
              const SizedBox(height: 10),
              // Email field; Disabled with initialValue set
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email (Cannot be edited)'),
                enabled: false,
                initialValue: user.email,
              ),
              const SizedBox(height: 10),
              // Mobile Number field
              TextFormField(
                controller: _mobileController,
                decoration: const InputDecoration(labelText: 'Mobile Number'),
                keyboardType: TextInputType.phone,
                validator: (val) => (val == null || val.trim().isEmpty || val.length != 10)
                    ? 'Enter correct mobile number'
                    : null,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const SizedBox(height: 10),
                  // Cancel button
                  ElevatedButton.icon(
                    onPressed: _isUpdating ? null : () => setState(() => isEditing = !isEditing),
                    icon: const Icon(Icons.cancel, size: 20),
                    label: const FittedBox(child: Text("Cancel")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Submit Button
                  ElevatedButton.icon(
                    onPressed: _isUpdating
                        ? null
                        : () async {
                      if (_formKey.currentState?.validate() ?? false) {
                        setState(() {
                          _isUpdating = true; // Start loading
                        });
                        
                        try {
                          Map<String, dynamic> fieldsToUpdate = {
                            "name": _nameController.text,
                            "username": _usernameController.text,
                            "mobile": _mobileController.text,
                          };
                          
                          final updatedUser = await UserService().updateUserProfile(fieldsToUpdate);
                          
                          if(mounted) {
                            Provider.of<UserProvider>(context, listen: false).setCurrentUser(updatedUser);
                            setState(() {
                              _loadUserData();
                              user = updatedUser;
                              isEditing = false;
                            });
                          }
                        } catch (e) {
                          debugPrint("Update error: $e");
                        } finally {
                          setState(() {
                            _isUpdating = false; // Stop loading
                          });
                        }
                      }
                    },
                    icon: _isUpdating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.send, size: 20),
                    label: _isUpdating ? const Text("Updating...") : const FittedBox(child: Text("Submit")),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 4,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalInfoCard(UserModel user, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Full Name', user.name, theme),
            if (user.username != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.alternate_email, 'Username', user.username!, theme),
            ],
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email, theme),
            if (user.mobile != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.phone, 'Mobile', user.mobile!, theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(UserModel user, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(
              Icons.calendar_today,
              'Member Since',
              _formatDate(user.createdAt),
              theme,
            ),
            if (user.passwordChangedAt != null) ...[
              const SizedBox(height: 16),
              _buildInfoRow(Icons.lock_reset, 'Password Changed', _formatDate(user.passwordChangedAt!), theme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuizActivityCard(UserModel user, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildInfoRow(Icons.quiz, 'Owned Quizzes', (user.ownedQuizzes?.length ?? 0).toString(), theme),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.play_circle, 'Played Quizzes', (user.playedQuiz?.length ?? 0).toString(), theme),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
