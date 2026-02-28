import 'package:flutter/material.dart';
import 'meditation_screen.dart';
import 'breathing_screen.dart';
import 'journal_screen.dart';
import 'mood_tracker_screen.dart';
import 'stats_screen.dart';
import 'profile_screen.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart' as custom;
import '../services/streak_service.dart';
import '../services/statistics_service.dart';
import '../widgets/custom_widgets.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeContent(),
    const StatsScreen(),
    const ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Stats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.purple.shade800,
        unselectedItemColor: Colors.grey.shade600,
        showUnselectedLabels: true,
      ),
    );
  }
}

// Home Content Widget
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final StatisticsService _statsService = StatisticsService();

  int _todayMinutes = 0;
  int _weeklyStreak = 0;
  int _longestStreak = 0;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    StreakService().loadStreaks();

    // Listen for auth changes to refresh data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<custom.AuthProvider>(context, listen: false);

      if (authProvider.fullName == 'User') {
        print('🏠 HomeContent: Refreshing user data...');
        authProvider.refreshUserDataFromFirestore();
      }
    });
  }

  Future<void> _loadUserData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Load real data from services
      _todayMinutes = await _statsService.getTodayMindfulnessMinutes();
      _weeklyStreak = StreakService().getOverallStreak();
      _longestStreak = StreakService().getLongestOverallStreak();

      // Load recent activities
      final activities = await _statsService.getUserActivities().first;
      _recentActivities = activities.take(3).map((activity) {
        return {
          'type': activity.activityType,
          'duration': activity.durationMinutes,
          'mood': activity.mood,
          'time': _formatTimeAgo(activity.date),
        };
      }).toList();

    } catch (e) {
      print('Error loading home data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  String _getActivityIcon(String type) {
    switch (type) {
      case 'meditation': return '🧘';
      case 'breathing': return '🌬️';
      case 'journal': return '📝';
      case 'mood': return '😊';
      default: return '✨';
    }
  }

  String _getActivityMessage(Map<String, dynamic> activity) {
    switch (activity['type']) {
      case 'meditation':
        return 'Meditated for ${activity['duration']} min';
      case 'breathing':
        return 'Breathing exercise (${activity['duration']} min)';
      case 'journal':
        return 'Wrote in journal';
      case 'mood':
        return 'Mood: ${activity['mood'] ?? 'Logged'}';
      default:
        return 'Completed activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<custom.AuthProvider>(context);
    final String displayName = authProvider.firstName;
    final bool isOffline = authProvider.isOffline;

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.purple.shade800),
              const SizedBox(height: 20),
              Text('Loading your wellness journey...'),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(
              top: 60,
              left: 24,
              right: 24,
              bottom: 30,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade800,
                  Colors.deepPurple.shade400,
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  'MindHeal Pro',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                // Welcome message with REAL name
                Text(
                  'Welcome back,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 18,
                  ),
                ),

                Row(
                  children: [
                    Text(
                      displayName != 'User' ? '$displayName!' : 'Guest!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isOffline) ...[
                      const SizedBox(width: 8),
                      Icon(
                        Icons.wifi_off,
                        color: Colors.white.withOpacity(0.7),
                        size: 20,
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 16),

                // Mood question
                Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 16),

                // Mood chips
                Row(
                  children: [
                    MoodChip(label: 'Happy'),
                    const SizedBox(width: 12),
                    MoodChip(label: 'Safe'),
                    const SizedBox(width: 12),
                    MoodChip(label: 'Sad'),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Daily Progress - Now with REAL data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Progress',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mindfulness Minutes',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // REAL minutes from today's activities
                      Text(
                        '$_todayMinutes/60 min',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _todayMinutes >= 60 ? Colors.green : Colors.purple.shade800,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 60,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: _todayMinutes / 60,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.grey.shade300,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    _todayMinutes >= 60 ? Colors.green : Colors.purple.shade800,
                                  ),
                                ),
                                Center(
                                  child: Text(
                                    '${((_todayMinutes / 60) * 100).toInt()}%',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: _todayMinutes >= 60 ? Colors.green : Colors.purple.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _todayMinutes >= 60 ? 'Goal Met! 🎉' : 'Daily Goal',
                            style: TextStyle(
                              fontSize: 10,
                              color: _todayMinutes >= 60 ? Colors.green : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Streak Counter Card - Now with REAL data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.orange.shade400,
                    Colors.deepOrange.shade600,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      TweenAnimationBuilder(
                        tween: Tween<double>(begin: 0.8, end: 1.2),
                        duration: const Duration(seconds: 1),
                        curve: Curves.easeInOut,
                        builder: (context, scale, child) {
                          return Transform.scale(
                            scale: scale as double,
                            child: const Icon(
                              Icons.local_fire_department,
                              size: 40,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Overall Wellness Streak',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  '$_weeklyStreak',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'days',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Best: $_longestStreak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emoji_emotions, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            StreakService().getMotivationalMessage(_weeklyStreak),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recent Activity Section (if there are activities)
          if (_recentActivities.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Recent Activity',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ..._recentActivities.map((activity) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Text(
                          _getActivityIcon(activity['type']),
                          style: const TextStyle(fontSize: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getActivityMessage(activity),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                activity['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )).toList(),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Offline Warning Banner
          if (isOffline)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.wifi_off, color: Colors.amber.shade800),
                    const SizedBox(width: 12),
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
                            'Showing cached data',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.amber.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: _loadUserData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 24),

          // Quick Activities Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Activities',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose an activity to improve your mental wellness',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),

                ActivityCard(
                  title: 'Meditation',
                  description: 'Guided mindfulness sessions',
                  duration: '5-15 min',
                  color: Colors.blue.shade50,
                  textColor: Colors.blue.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MeditationScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ActivityCard(
                  title: 'Breathing',
                  description: 'Calm your nervous system',
                  duration: '5-15 min',
                  color: Colors.green.shade50,
                  textColor: Colors.green.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const BreathingScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ActivityCard(
                  title: 'Journal',
                  description: 'Write your thoughts and feelings',
                  duration: '10 min',
                  color: Colors.orange.shade50,
                  textColor: Colors.orange.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const JournalScreen()),
                    );
                  },
                ),
                const SizedBox(height: 16),
                ActivityCard(
                  title: 'Mood Tracker',
                  description: 'Track your daily emotions',
                  duration: '5 min',
                  color: Colors.purple.shade50,
                  textColor: Colors.purple.shade800,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MoodTrackerScreen()),
                    );
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Daily Tip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.amber.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.lightbulb_outline,
                    color: Colors.amber.shade700,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Daily Tip: Take 5 deep breaths when feeling stressed',
                      style: TextStyle(
                        color: Color(0xFF7D4E00),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
    );
  }
}

// Profile Screen (simplified version) removed

// MoodChip and ActivityCard removed and extracted to custom_widgets.dart
