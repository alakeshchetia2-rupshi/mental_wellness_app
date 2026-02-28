import 'package:flutter/material.dart';
import 'dart:async';
import '../services/streak_service.dart';
import '../services/statistics_service.dart';
import '../models/user_activity.dart';

class MeditationScreen extends StatefulWidget {
  const MeditationScreen({super.key});

  @override
  State<MeditationScreen> createState() => _MeditationScreenState();
}

class _MeditationScreenState extends State<MeditationScreen> {
  final StatisticsService _statsService = StatisticsService();

  // Timer variables
  int _selectedDuration = 300; // 5 minutes in seconds (default)
  int _secondsRemaining = 300;
  bool _isMeditating = false;
  Timer? _timer;

  // Duration options in minutes
  final List<int> _durationOptions = [1, 3, 5, 10, 15];

  // Background colors for different states
  final List<Color> _calmColors = [
    const Color(0xFF667EEA),
    const Color(0xFF764BA2),
    const Color(0xFF6A11CB),
    const Color(0xFF2575FC),
  ];
  int _colorIndex = 0;

  // Real user stats
  int _todayMinutes = 0;
  int _weeklyMinutes = 0;
  int _meditationStreak = 0;
  int _totalSessions = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserStats();

    // Cycle through calm colors every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isMeditating && mounted) {
        setState(() {
          _colorIndex = (_colorIndex + 1) % _calmColors.length;
        });
      }
    });
  }

  Future<void> _loadUserStats() async {
    try {
      // Get real data from services
      _todayMinutes = await _statsService.getTodayMindfulnessMinutes();
      _meditationStreak = StreakService().getMeditationStreak();
      _totalSessions = StreakService().getTotalMeditationSessions();

      // Calculate weekly minutes
      final weeklyProgress = await _statsService.getWeeklyProgress();
      _weeklyMinutes = weeklyProgress.values.fold(0, (sum, minutes) => sum + minutes);

    } catch (e) {
      print('Error loading meditation stats: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _startMeditation() async {
    setState(() {
      _isMeditating = true;
      _secondsRemaining = _selectedDuration;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRemaining > 0) {
            _secondsRemaining--;
          } else {
            _timer?.cancel();
            _isMeditating = false;
            _saveMeditationSession();
            _showCompletionDialog();
          }
        });
      }
    });
  }

  Future<void> _saveMeditationSession() async {
    int minutesMeditated = _selectedDuration ~/ 60;

    // Save activity to Firestore
    final activity = UserActivity(
      date: DateTime.now(),
      activityType: 'meditation',
      durationMinutes: minutesMeditated,
    );

    try {
      await _statsService.saveActivity(activity);

      // Update streak
      StreakService().updateStreak('meditation');

      // Refresh stats
      await _loadUserStats();

      print('✅ Meditation session saved: $minutesMeditated minutes');
    } catch (e) {
      print('❌ Error saving meditation session: $e');
    }
  }

  void _pauseMeditation() {
    setState(() {
      _isMeditating = false;
    });
    _timer?.cancel();
  }

  void _resetMeditation() {
    setState(() {
      _isMeditating = false;
      _secondsRemaining = _selectedDuration;
    });
    _timer?.cancel();
  }

  void _setDuration(int minutes) {
    setState(() {
      _selectedDuration = minutes * 60;
      if (!_isMeditating) {
        _secondsRemaining = _selectedDuration;
      }
    });
  }

  void _showCompletionDialog() {
    int minutesMeditated = _selectedDuration ~/ 60;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("🧘 Meditation Complete!"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("You've completed $minutesMeditated minutes of mindfulness."),
            const SizedBox(height: 16),

            // Streak card with REAL data
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade50, Colors.purple.shade100],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_fire_department,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Meditation Streak',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$_meditationStreak days in a row',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                        Text(
                          'Longest: ${StreakService().getLongestMeditationStreak()} days',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.purple.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Today's progress
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildDialogStat('Today', '$_todayMinutes min', Icons.today),
                _buildDialogStat('Total', '$_totalSessions', Icons.analytics),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _resetMeditation();
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.purple.shade400, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double _getProgress() {
    return (_selectedDuration - _secondsRemaining) / _selectedDuration;
  }

  String _formatMinutes(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    } else {
      double hours = minutes / 60;
      return '${hours.toStringAsFixed(1)} hrs';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _calmColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.white),
                SizedBox(height: 20),
                Text(
                  'Preparing your meditation...',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(seconds: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _calmColors[_colorIndex],
              _calmColors[(_colorIndex + 1) % _calmColors.length],
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Back button and title
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Guided Meditation',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Timer display
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Progress circle
                          SizedBox(
                            width: 280,
                            height: 280,
                            child: CircularProgressIndicator(
                              value: _getProgress(),
                              strokeWidth: 8,
                              backgroundColor: Colors.white.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),

                          // Timer text
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_secondsRemaining),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 64,
                                  fontWeight: FontWeight.w300,
                                  fontFamily: 'Monospace',
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _isMeditating ? 'Breathe deeply...' : 'Ready to begin',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      // Duration selector (only when not meditating)
                      if (!_isMeditating) ...[
                        const Text(
                          'Select Duration',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _durationOptions.map((minutes) {
                              bool isSelected = minutes == (_selectedDuration ~/ 60);
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                child: ChoiceChip(
                                  label: Text('$minutes min'),
                                  selected: isSelected,
                                  onSelected: (_) => _setDuration(minutes),
                                  selectedColor: Colors.white,
                                  labelStyle: TextStyle(
                                    color: isSelected ? _calmColors[_colorIndex] : Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  backgroundColor: Colors.white.withOpacity(0.2),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],

                      // Control buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (!_isMeditating && _secondsRemaining != _selectedDuration)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 32),
                              color: Colors.white,
                              onPressed: _resetMeditation,
                            ),

                          const SizedBox(width: 40),

                          // Main start/pause button
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                _isMeditating ? Icons.pause : Icons.play_arrow,
                                size: 40,
                              ),
                              color: _calmColors[_colorIndex],
                              onPressed: () {
                                if (_isMeditating) {
                                  _pauseMeditation();
                                } else {
                                  _startMeditation();
                                }
                              },
                            ),
                          ),

                          const SizedBox(width: 40),

                          if (_isMeditating)
                            IconButton(
                              icon: const Icon(Icons.stop, size: 32),
                              color: Colors.white,
                              onPressed: _resetMeditation,
                            ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Meditation tips
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Meditation Tips',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Find a comfortable position. Focus on your breath. '
                                  'If your mind wanders, gently bring it back.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Bottom stats with REAL data
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(
                              Icons.timer,
                              'Today',
                              _formatMinutes(_todayMinutes),
                            ),
                            _buildStatItem(
                              Icons.calendar_today,
                              'This Week',
                              _formatMinutes(_weeklyMinutes),
                            ),
                            _buildStatItem(
                              Icons.star,
                              'Streak',
                              '$_meditationStreak days',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.7), size: 24),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}