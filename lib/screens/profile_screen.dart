import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import '../providers/auth_provider.dart' as custom;
import '../services/streak_service.dart';
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/custom_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // App settings
  bool _darkMode = false;
  bool _dailyReminders = true;
  bool _weeklyReports = false;
  bool _vibrationFeedback = true;

  // User achievements
  List<Map<String, dynamic>> _achievements = [];
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _updateAchievements();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndRefreshProfile();
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _darkMode = prefs.getBool('dark_mode') ?? false;
        _dailyReminders = prefs.getBool('daily_reminders') ?? true;
        _weeklyReports = prefs.getBool('weekly_reports') ?? false;
        _vibrationFeedback = prefs.getBool('vibration_feedback') ?? true;
      });
    }
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _checkAndRefreshProfile() async {
    final authProvider = Provider.of<custom.AuthProvider>(context, listen: false);

    if (authProvider.fullName == 'User') {
      print('👤 ProfileScreen: Name is missing, fetching from Firestore...');
      if (mounted) setState(() => _isRefreshing = true);

      await authProvider.refreshUserDataFromFirestore();

      if (mounted) {
        setState(() => _isRefreshing = false);
        _updateAchievements();
      }
    }
  }

  Future<void> _manualRefresh() async {
    if (mounted) setState(() => _isRefreshing = true);

    final authProvider = Provider.of<custom.AuthProvider>(context, listen: false);
    await authProvider.refreshUserDataFromFirestore();

    if (mounted) {
      _updateAchievements();
      setState(() => _isRefreshing = false);
      _showSnackbar('Profile refreshed!');
    }
  }

  void _updateAchievements() {
    final overallStreak = StreakService().getOverallStreak();
    final longestStreak = StreakService().getLongestOverallStreak();

    _achievements = [
      {
        'icon': Icons.local_fire_department,
        'title': 'First Spark',
        'description': '3-day overall streak',
        'earned': longestStreak >= 3,
        'date': longestStreak >= 3 ? 'Earned' : '3 days needed',
        'progress': longestStreak >= 3 ? 100 : (longestStreak / 3 * 100).clamp(0, 100),
        'color': Colors.orange,
      },
      {
        'icon': Icons.whatshot,
        'title': 'Week Warrior',
        'description': '7-day overall streak',
        'earned': longestStreak >= 7,
        'date': longestStreak >= 7 ? 'Earned' : '7 days needed',
        'progress': longestStreak >= 7 ? 100 : (longestStreak / 7 * 100).clamp(0, 100),
        'color': Colors.deepOrange,
      },
      {
        'icon': Icons.stars,
        'title': 'Habit Master',
        'description': '21-day overall streak',
        'earned': longestStreak >= 21,
        'date': longestStreak >= 21 ? 'Earned' : '21 days needed',
        'progress': longestStreak >= 21 ? 100 : (longestStreak / 21 * 100).clamp(0, 100),
        'color': Colors.amber,
      },
    ];
  }

  String _getJoinDate(User? user) {
    if (user == null) return 'January 2024';
    if (user.metadata.creationTime != null) {
      final date = user.metadata.creationTime!;
      return '${_getMonth(date.month)} ${date.year}';
    }
    return 'February 2025';
  }

  String _getMonth(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  void _editProfile() {
    final authProvider = Provider.of<custom.AuthProvider>(context, listen: false);
    final currentName = authProvider.fullName;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Name',
                  hintText: currentName != 'User' ? currentName : 'Enter name',
                ),
                onChanged: (value) {
                  // In a real app, you'd update this in Firebase
                },
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Email',
                  hintText: authProvider.email,
                  enabled: false,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('Profile update feature coming soon!');
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportData() {
    _showSnackbar('Data export feature coming soon!');
  }

  void _clearData() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Clear All Data?'),
        content: Text('This will delete all your data. This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackbar('All data cleared (demo only)');
            },
            child: Text(
              'Clear All',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About MindHeal Pro'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Version 1.0.0',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              SizedBox(height: 12),
              Text(
                'MindHeal Pro is your personal mental wellness companion.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Guided meditation sessions'),
              Text('• Breathing exercises'),
              Text('• Daily journaling'),
              Text('• Mood tracking'),
              SizedBox(height: 16),
              Text(
                'Created with ❤️ for better mental health',
                style: TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ✅ USE CUSTOM AUTH PROVIDER WITH ALIAS
    final authProvider = Provider.of<custom.AuthProvider>(context);

    // ✅ Get data from AuthProvider
    final String fullName = authProvider.fullName;
    final String userEmail = authProvider.email;
    final bool isOffline = authProvider.isOffline; // ✅ ADD THIS - Check if offline

    // ✅ Create display name with fallbacks
    final String displayName = fullName != 'User'
        ? fullName
        : (userEmail != 'user@example.com'
        ? userEmail.split('@')[0]  // Use email username as fallback
        : 'User');

    // Get first letter for avatar
    final String firstLetter = displayName != 'User' && displayName.isNotEmpty
        ? displayName[0].toUpperCase()
        : '?';

    print('👤 Profile screen showing full name: $fullName, display name: $displayName, email: $userEmail, offline: $isOffline');

    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: Colors.purple.shade800,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // ✅ ADD THIS - Show offline indicator in app bar
          if (isOffline)
            IconButton(
              icon: Icon(Icons.wifi_off, color: Colors.white),
              onPressed: () {
                _showSnackbar('You are offline. Check your internet connection.');
              },
            ),
          // Refresh button
          IconButton(
            icon: _isRefreshing
                ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                )
            )
                : Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _manualRefresh,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Card
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar with first letter and loading indicator
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.purple.shade400,
                                  Colors.purple.shade700,
                                ],
                              ),
                            ),
                            child: Center(
                              child: _isRefreshing
                                  ? CircularProgressIndicator(color: Colors.white)
                                  : Text(
                                firstLetter,
                                style: TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: _editProfile,
                            child: Container(
                              padding: EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.edit,
                                size: 18,
                                color: Colors.purple,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // ✅ FIX: Replace the existing name text with this Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            displayName, // Shows name or email username
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          // Show offline indicator if needed
                          if (isOffline)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Icon(
                                Icons.wifi_off,
                                color: Colors.grey.shade400,
                                size: 16,
                              ),
                            ),
                        ],
                      ),

                      SizedBox(height: 4),

                      // Show email
                      Text(
                        userEmail,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                        ),
                      ),

                      SizedBox(height: 8),

                      // Show join date
                      Text(
                        'Member since ${_getJoinDate(authProvider.user)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),

                      SizedBox(height: 20),

                      // Quick stats
                      Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            MiniStat(
                                title: 'Meditation',
                                value: '12 ses',
                                icon: Icons.spa,
                                color: Colors.purple
                            ),
                            MiniStat(
                                title: 'Breathing',
                                value: '8 ses',
                                icon: Icons.air,
                                color: Colors.blue
                            ),
                            MiniStat(
                                title: 'Streak',
                                value: '${StreakService().getOverallStreak()} days',
                                icon: Icons.local_fire_department,
                                color: Colors.orange
                            ),
                          ],
                        ),
                      ),

                      // ✅ ADD THIS - Show retry button if offline
                      if (isOffline)
                        Padding(
                          padding: const EdgeInsets.only(top: 16),
                          child: ElevatedButton.icon(
                            onPressed: _manualRefresh,
                            icon: Icon(Icons.refresh, size: 18),
                            label: Text('Retry to load profile'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange.shade100,
                              foregroundColor: Colors.orange.shade800,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // ✅ ADD THIS - Offline warning banner
                if (isOffline)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off, color: Colors.amber.shade800),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'You are offline',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                              Text(
                                'Showing cached data. Connect to internet to update.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.amber.shade800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                // Streak Section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.orange.shade50, Colors.orange.shade100],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade200,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.local_fire_department,
                              color: Colors.orange.shade800,
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Your Streaks',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      // Overall streak with animation
                      TweenAnimationBuilder(
                        tween: Tween<double>(
                            begin: 0,
                            end: StreakService().getOverallStreak().toDouble()
                        ),
                        duration: Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Streak',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      '${value.toInt()} days',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.whatshot,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // App Settings
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'App Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      SizedBox(height: 16),

                      SettingSwitch(
                        title: 'Dark Mode',
                        subtitle: 'Use dark theme',
                        value: _darkMode,
                        icon: Icons.dark_mode,
                        color: Colors.grey.shade800,
                        onChanged: (value) {
                          setState(() => _darkMode = value);
                          _saveSetting('dark_mode', value);
                        },
                      ),

                      SettingSwitch(
                        title: 'Daily Reminders',
                        subtitle: 'Get daily practice reminders',
                        value: _dailyReminders,
                        icon: Icons.notifications,
                        color: Colors.blue,
                        onChanged: (value) {
                          setState(() => _dailyReminders = value);
                          _saveSetting('daily_reminders', value);
                        },
                      ),

                      SettingSwitch(
                        title: 'Weekly Reports',
                        subtitle: 'Receive weekly progress email',
                        value: _weeklyReports,
                        icon: Icons.email,
                        color: Colors.green,
                        onChanged: (value) {
                          setState(() => _weeklyReports = value);
                          _saveSetting('weekly_reports', value);
                        },
                      ),

                      SettingSwitch(
                        title: 'Vibration Feedback',
                        subtitle: 'Haptic feedback',
                        value: _vibrationFeedback,
                        icon: Icons.vibration,
                        color: Colors.orange,
                        onChanged: (value) {
                          setState(() => _vibrationFeedback = value);
                          _saveSetting('vibration_feedback', value);
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Achievements
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Achievements',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            ),
                          ),
                          Text(
                            '${_achievements.where((a) => a['earned'] == true).length}/${_achievements.length}',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 16),

                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _achievements.length,
                          itemBuilder: (context, index) {
                            final achievement = _achievements[index];
                            return _buildAchievementCard(achievement);
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Data Management
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Data Management',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),

                      SizedBox(height: 16),

                      _buildDataOption(
                        'Export Data',
                        'Download your data as CSV',
                        Icons.download,
                        Colors.blue,
                        _exportData,
                      ),

                      _buildDataOption(
                        'Clear All Data',
                        'Delete all app data',
                        Icons.delete,
                        Colors.red,
                        _clearData,
                      ),

                      _buildDataOption(
                        'About MindHeal Pro',
                        'App information and version',
                        Icons.info,
                        Colors.grey,
                        _showAboutDialog,
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 30),

                // Logout button
                Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      await authProvider.signOut();
                      Navigator.pushReplacementNamed(context, '/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade400,
                      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'LOG OUT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

// _buildMiniStat and _buildSettingSwitch removed and moved to custom_widgets.dart

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      width: 150,
      margin: EdgeInsets.only(right: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: achievement['earned']
            ? achievement['color'].withOpacity(0.1)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement['earned']
              ? achievement['color'].withOpacity(0.3)
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: achievement['earned']
                      ? achievement['color'].withOpacity(0.2)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  achievement['icon'],
                  size: 16,
                  color: achievement['earned']
                      ? achievement['color']
                      : Colors.grey.shade400,
                ),
              ),
              Spacer(),
              if (achievement['earned'])
                Icon(Icons.check_circle, size: 16, color: Colors.green),
            ],
          ),
          SizedBox(height: 8),
          Text(
            achievement['title'],
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: achievement['earned']
                  ? Colors.grey.shade800
                  : Colors.grey.shade500,
            ),
          ),
          SizedBox(height: 2),
          LinearProgressIndicator(
            value: achievement['progress'] / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              achievement['earned']
                  ? Colors.green
                  : achievement['color'],
            ),
          ),
          SizedBox(height: 4),
          Text(
            achievement['date'],
            style: TextStyle(
              fontSize: 10,
              color: achievement['earned']
                  ? Colors.green
                  : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataOption(String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}