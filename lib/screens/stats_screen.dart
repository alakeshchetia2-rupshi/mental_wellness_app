import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/statistics_service.dart';
import '../services/streak_service.dart';
import '../providers/auth_provider.dart' as custom;
import '../models/user_activity.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StatisticsService _statsService = StatisticsService();

  // Real data variables
  List<UserActivity> _recentActivities = [];
  Map<String, int> _weeklySummary = {};
  Map<String, int> _moodDistribution = {};
  Map<DateTime, int> _weeklyProgress = {};
  Map<String, int> _activityCounts = {};
  int _totalMeditationMinutes = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserStats();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserStats() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      // Load all real data in parallel for better performance
      await Future.wait([
        _loadRecentActivities(),
        _loadWeeklySummary(),
        _loadMoodDistribution(),
        _loadWeeklyProgress(),
        _loadActivityCounts(),
        _loadTotalMeditationMinutes(),
      ]);
    } catch (e) {
      print('Error loading stats: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error loading statistics')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadRecentActivities() async {
    final activities = await _statsService.getUserActivities().first;
    if (mounted) {
      setState(() {
        _recentActivities = activities.take(4).toList();
      });
    }
  }

  Future<void> _loadWeeklySummary() async {
    final summary = await _statsService.getWeeklyActivitySummary();
    if (mounted) {
      setState(() {
        _weeklySummary = summary;
      });
    }
  }

  Future<void> _loadMoodDistribution() async {
    final distribution = await _statsService.getMoodDistribution();
    if (mounted) {
      setState(() {
        _moodDistribution = distribution;
      });
    }
  }

  Future<void> _loadWeeklyProgress() async {
    final progress = await _statsService.getWeeklyProgress();
    if (mounted) {
      setState(() {
        _weeklyProgress = progress;
      });
    }
  }

  Future<void> _loadActivityCounts() async {
    final counts = await _statsService.getActivityCounts();
    if (mounted) {
      setState(() {
        _activityCounts = counts;
      });
    }
  }

  Future<void> _loadTotalMeditationMinutes() async {
    final minutes = await _statsService.getTotalMeditationMinutes();
    if (mounted) {
      setState(() {
        _totalMeditationMinutes = minutes;
      });
    }
  }

  int _getMoodValue(String? mood) {
    switch (mood) {
      case 'Happy': return 5;
      case 'Calm': return 4;
      case 'Neutral': return 3;
      case 'Sad': return 2;
      case 'Anxious': return 1;
      default: return 3;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return 'Today';
    } else if (date.day == now.day - 1 && date.month == now.month && date.year == now.year) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }

  double _getAverageMood() {
    if (_moodDistribution.isEmpty) return 0;

    int total = 0;
    int count = 0;
    _moodDistribution.forEach((mood, value) {
      total += _getMoodValue(mood) * value;
      count += value;
    });

    return count > 0 ? total / count : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.purple.shade800),
              SizedBox(height: 20),
              Text('Loading your statistics...'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with Refresh button
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Your Statistics',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.refresh, color: Colors.purple.shade700),
                    onPressed: _loadUserStats,
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.purple.shade700,
                unselectedLabelColor: Colors.grey.shade600,
                indicatorColor: Colors.purple.shade700,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Mood Trends'),
                  Tab(text: 'Activities'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildMoodTrendsTab(),
                  _buildActivitiesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Overview Tab - Now with REAL data
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Streak Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_fire_department,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Streak',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${StreakService().getOverallStreak()}',
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
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Best: ${StreakService().getLongestOverallStreak()}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Stats Grid with REAL data
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard(
                'Total Sessions',
                '${(_activityCounts['meditation'] ?? 0) + (_activityCounts['breathing'] ?? 0)}',
                Icons.timer,
                Colors.purple,
              ),
              _buildStatCard(
                'Journal Entries',
                '${_activityCounts['journal'] ?? 0}',
                Icons.edit_note,
                Colors.green,
              ),
              _buildStatCard(
                'Mood Logs',
                '${_activityCounts['mood'] ?? 0}',
                Icons.emoji_emotions,
                Colors.orange,
              ),
              _buildStatCard(
                'Minutes Meditated',
                '$_totalMeditationMinutes',
                Icons.spa,
                Colors.blue,
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Recent Activity with REAL data
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
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
                const Text(
                  'Recent Activity',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_recentActivities.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No activities yet. Start your journey!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ..._recentActivities.map((activity) => _buildActivityItem(
                    activity.activityType,
                    activity.durationMinutes > 0 ? '${activity.durationMinutes} min' :
                    (activity.mood ?? 'Completed'),
                    _formatDate(activity.date),
                    _getActivityIcon(activity.activityType),
                    _getActivityColor(activity.activityType),
                  )).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Mood Trends Tab - Now with REAL data
  Widget _buildMoodTrendsTab() {
    // Prepare weekly mood data from real activities
    List<Map<String, dynamic>> weeklyMoodData = [];
    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final day = now.subtract(Duration(days: i));
      final dayKey = DateFormat('EEE').format(day);

      // Find mood for this day from recent activities
      int? moodValue;
      for (var activity in _recentActivities) {
        if (activity.activityType == 'mood' &&
            activity.date.day == day.day &&
            activity.date.month == day.month) {
          moodValue = _getMoodValue(activity.mood);
          break;
        }
      }

      weeklyMoodData.add({
        'day': dayKey,
        'mood': moodValue ?? 3, // Default to neutral if no mood logged
      });
    }

    final avgMood = _getAverageMood();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Mood Chart Card
          Container(
            padding: const EdgeInsets.all(20),
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
                    const Text(
                      'Weekly Mood',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Avg: ${avgMood.toStringAsFixed(1)}',
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: weeklyMoodData.map((data) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 30,
                            height: data['mood'] * 30.0,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.purple.shade300,
                                  Colors.purple.shade700,
                                ],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['day'],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Mood Distribution with REAL data
          Container(
            padding: const EdgeInsets.all(20),
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
                const Text(
                  'Mood Distribution',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (_moodDistribution.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No mood data yet. Track your mood to see patterns!',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                else ...[
                  _buildMoodDistributionItem('Happy', _moodDistribution['Happy'] ?? 0, Colors.amber),
                  _buildMoodDistributionItem('Calm', _moodDistribution['Calm'] ?? 0, Colors.blue),
                  _buildMoodDistributionItem('Neutral', _moodDistribution['Neutral'] ?? 0, Colors.grey),
                  _buildMoodDistributionItem('Sad', _moodDistribution['Sad'] ?? 0, Colors.indigo),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Activities Tab - Now with REAL data
  Widget _buildActivitiesTab() {
    final totalActivities = (_activityCounts['meditation'] ?? 0) +
        (_activityCounts['breathing'] ?? 0) +
        (_activityCounts['journal'] ?? 0) +
        (_activityCounts['mood'] ?? 0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Activity Summary with REAL counts
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.purple.shade400, Colors.purple.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildActivitySummaryItem(
                      'Meditation',
                      _activityCounts['meditation'] ?? 0,
                      Icons.spa,
                    ),
                    _buildActivitySummaryItem(
                      'Breathing',
                      _activityCounts['breathing'] ?? 0,
                      Icons.air,
                    ),
                    _buildActivitySummaryItem(
                      'Journal',
                      _activityCounts['journal'] ?? 0,
                      Icons.edit,
                    ),
                    _buildActivitySummaryItem(
                      'Mood',
                      _activityCounts['mood'] ?? 0,
                      Icons.emoji_emotions,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Activities: $totalActivities',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Activity Breakdown with REAL data
          Container(
            padding: const EdgeInsets.all(20),
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
                const Text(
                  'Activity Breakdown',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildProgressItem(
                  'Meditation',
                  _activityCounts['meditation'] ?? 0,
                  30, // Goal: 30 sessions
                  Colors.purple,
                ),
                _buildProgressItem(
                  'Breathing',
                  _activityCounts['breathing'] ?? 0,
                  30,
                  Colors.blue,
                ),
                _buildProgressItem(
                  'Journal',
                  _activityCounts['journal'] ?? 0,
                  20,
                  Colors.green,
                ),
                _buildProgressItem(
                  'Mood Tracking',
                  _activityCounts['mood'] ?? 0,
                  30,
                  Colors.orange,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Weekly Summary
          Container(
            padding: const EdgeInsets.all(20),
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
                const Text(
                  'This Week',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildWeekStat('Meditation', _weeklySummary['meditation'] ?? 0),
                _buildWeekStat('Breathing', _weeklySummary['breathing'] ?? 0),
                _buildWeekStat('Journal', _weeklySummary['journal'] ?? 0),
                _buildWeekStat('Mood', _weeklySummary['mood'] ?? 0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Helper Widgets
  Widget _buildActivitySummaryItem(String label, int count, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 4),
        Text(
          '$count',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildWeekStat(String label, int count) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(label),
          ),
          Text(
            '$count times',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, String time, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodDistributionItem(String mood, int count, Color color) {
    int total = _moodDistribution.values.fold(0, (sum, item) => sum + item);
    double percentage = total > 0 ? (count / total * 100) : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mood,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, int current, int goal, Color color) {
    double progress = goal > 0 ? current / goal : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                '$current/$goal',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'meditation': return Icons.spa;
      case 'breathing': return Icons.air;
      case 'journal': return Icons.edit;
      case 'mood': return Icons.emoji_emotions;
      default: return Icons.favorite;
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'meditation': return Colors.purple;
      case 'breathing': return Colors.blue;
      case 'journal': return Colors.green;
      case 'mood': return Colors.orange;
      default: return Colors.grey;
    }
  }
}