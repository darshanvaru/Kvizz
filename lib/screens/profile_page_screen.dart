import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/UserModel.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = Provider.of<UserProvider>(context).currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Profile')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_off, size: 80, color: Colors.grey),
              SizedBox(height: 16),
              Text('No user data available', style: theme.textTheme.titleMedium),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Profile Picture
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
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
                    SizedBox(height: 40),
                    _buildProfileAvatar(user, theme),
                    SizedBox(height: 12),
                    Text(
                      user.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (user.username != null) ...[
                      SizedBox(height: 4),
                      Text(
                        '@${user.username}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Profile Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick Stats Cards
                  if (user.stats != null) _buildQuickStats(user.stats!, theme),
                  SizedBox(height: 20),

                  // Personal Information Section
                  _buildSectionTitle('Personal Information', theme),
                  SizedBox(height: 12),
                  _buildPersonalInfoCard(user, theme),
                  SizedBox(height: 20),

                  // Account Information Section
                  _buildSectionTitle('Account Information', theme),
                  SizedBox(height: 12),
                  _buildAccountInfoCard(user, theme),
                  SizedBox(height: 20),

                  // Quiz Activity Section
                  _buildSectionTitle('Quiz Activity', theme),
                  SizedBox(height: 12),
                  _buildQuizActivityCard(user, theme),
                  SizedBox(height: 20),

                  // Settings Section
                  if (user.settings != null) ...[
                    _buildSectionTitle('Preferences', theme),
                    SizedBox(height: 12),
                    _buildSettingsCard(user.settings!, theme),
                    SizedBox(height: 20),
                  ],

                  // Account Status Section
                  _buildSectionTitle('Account Status', theme),
                  SizedBox(height: 12),
                  _buildAccountStatusCard(user, theme),
                  SizedBox(height: 40),
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
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 3),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Colors.white,
        backgroundImage: user.photo != null ? NetworkImage(user.photo!) : null,
        child: user.photo == null
            ? Text(
          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        )
            : null,
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
            Colors.blue,
            theme,
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Total Score',
            stats.totalScore.toString(),
            Icons.star,
            Colors.amber,
            theme,
          ),
        ),
        SizedBox(width: 12),
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
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, ThemeData theme) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
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
              SizedBox(height: 16),
              _buildInfoRow(Icons.alternate_email, 'Username', user.username!, theme),
            ],
            SizedBox(height: 16),
            _buildInfoRow(Icons.email, 'Email', user.email, theme),
            if (user.mobile != null) ...[
              SizedBox(height: 16),
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
              SizedBox(height: 16),
              _buildInfoRow(
                Icons.lock_reset,
                'Password Changed',
                _formatDate(user.passwordChangedAt!),
                theme,
              ),
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
            _buildInfoRow(
              Icons.quiz,
              'Owned Quizzes',
              user.ownedQuizzes?.length.toString() ?? '0',
              theme,
            ),
            SizedBox(height: 16),
            _buildInfoRow(
              Icons.play_circle,
              'Played Quizzes',
              user.playedQuiz?.length.toString() ?? '0',
              theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(UserSettings settings, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    settings.darkMode ? Icons.dark_mode : Icons.light_mode,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Theme Preference',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        settings.darkMode ? 'Dark Mode' : 'Light Mode',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountStatusCard(UserModel user, ThemeData theme) {
    bool isActive = user.active ?? true;
    bool isDeleted = user.deletedAt != null;

    Color statusColor = isDeleted ? Colors.red : (isActive ? Colors.green : Colors.orange);
    String statusText = isDeleted ? 'Deleted' : (isActive ? 'Active' : 'Inactive');
    IconData statusIcon = isDeleted ? Icons.delete : (isActive ? Icons.check_circle : Icons.pause_circle);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(statusIcon, color: statusColor, size: 20),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Status',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        statusText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (isDeleted) ...[
              SizedBox(height: 16),
              _buildInfoRow(
                Icons.delete_forever,
                'Deleted On',
                _formatDate(user.deletedAt!),
                theme,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary, size: 20),
        ),
        SizedBox(width: 16),
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
              SizedBox(height: 2),
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
