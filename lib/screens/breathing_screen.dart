import 'package:flutter/material.dart';
import 'dart:async';
import '../services/streak_service.dart'; // Add this import

class BreathingScreen extends StatefulWidget {
  const BreathingScreen({super.key});

  @override
  State<BreathingScreen> createState() => _BreathingScreenState();
}

class _BreathingScreenState extends State<BreathingScreen>
    with SingleTickerProviderStateMixin {
  // Animation controller
  late AnimationController _controller;
  late Animation<double> _animation;

  // Breathing states
  bool _isBreathing = false;
  String _breathPhase = 'Ready';
  int _cycleCount = 0;

  // Breathing pattern: Inhale (4s) → Hold (7s) → Exhale (8s)
  final Map<String, double> _pattern = {
    'inhale': 4.0,
    'hold_in': 7.0,
    'exhale': 8.0,
    'hold_out': 0.0,
  };

  String _currentPhase = 'inhale';
  Timer? _breathTimer;
  int _secondsInPhase = 0;

  // Available breathing patterns
  final List<Map<String, dynamic>> _patterns = [
    {
      'name': 'Calm (4-7-8)',
      'description': 'For stress relief and relaxation',
      'inhale': 4,
      'hold_in': 7,
      'exhale': 8,
      'hold_out': 0,
      'color': Colors.blue,
    },
    {
      'name': 'Box (4-4-4-4)',
      'description': 'For focus and balance',
      'inhale': 4,
      'hold_in': 4,
      'exhale': 4,
      'hold_out': 4,
      'color': Colors.green,
    },
    {
      'name': 'Energy (4-1-2)',
      'description': 'For morning energy boost',
      'inhale': 4,
      'hold_in': 1,
      'exhale': 2,
      'hold_out': 0,
      'color': Colors.orange,
    },
  ];

  int _selectedPatternIndex = 0;

  @override
  void initState() {
    super.initState();

    // Setup animation controller
    _controller = AnimationController(
      duration: Duration(seconds: 4),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0.8, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _controller.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _controller.forward();
      }
    });

    _loadPattern(_patterns[_selectedPatternIndex]);
  }

  void _loadPattern(Map<String, dynamic> pattern) {
    setState(() {
      _pattern['inhale'] = pattern['inhale'].toDouble();
      _pattern['hold_in'] = pattern['hold_in'].toDouble();
      _pattern['exhale'] = pattern['exhale'].toDouble();
      _pattern['hold_out'] = pattern['hold_out'].toDouble();
    });
  }

  void _startBreathing() {
    if (_isBreathing) return;

    setState(() {
      _isBreathing = true;
      _cycleCount = 0;
      _currentPhase = 'inhale';
      _secondsInPhase = 0;
    });

    _controller.duration = Duration(seconds: _pattern['inhale']!.toInt());
    _controller.forward();

    _updateBreathPhase();
    _startBreathTimer();
  }

  // ✅ UPDATED: Streak tracking when stopping
  void _stopBreathing() {
    setState(() {
      _isBreathing = false;
      _breathPhase = 'Ready';
    });

    _breathTimer?.cancel();
    _controller.stop();
    _controller.value = 0.0;

    // ✅ UPDATE STREAK if user completed at least one cycle
    if (_cycleCount > 0) {
      // Update breathing streak
      StreakService().updateStreak('breathing');

      // Show streak notification
      _showStreakNotification();
    }
  }

  // ✅ New method to show streak notification
  void _showStreakNotification() {
    final currentStreak = StreakService().getBreathingStreak();
    final longestStreak = StreakService().getLongestBreathingStreak();
    final totalSessions = StreakService().getTotalBreathingSessions();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Container(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_fire_department,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Breathing Complete!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, size: 14, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          'Streak: $currentStreak days  |  Best: $longestStreak days',
                          style: TextStyle(
                            color: Colors.blue.shade600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Total sessions: $totalSessions',
                      style: TextStyle(
                        color: Colors.blue.shade400,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        duration: Duration(seconds: 4),
        backgroundColor: Colors.blue.shade50,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _startBreathTimer() {
    _breathTimer?.cancel();

    _breathTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        _secondsInPhase++;

        double phaseDuration = _pattern[_currentPhase]!;
        if (_secondsInPhase >= phaseDuration) {
          _secondsInPhase = 0;
          _nextBreathPhase();
        }

        _updateBreathPhase();
      });
    });
  }

  void _nextBreathPhase() {
    switch (_currentPhase) {
      case 'inhale':
        _currentPhase = 'hold_in';
        _controller.stop();
        break;
      case 'hold_in':
        _currentPhase = 'exhale';
        _controller.duration = Duration(seconds: _pattern['exhale']!.toInt());
        _controller.reverse();
        break;
      case 'exhale':
        _currentPhase = _pattern['hold_out']! > 0 ? 'hold_out' : 'inhale';
        if (_currentPhase == 'inhale') {
          _cycleCount++;
        }
        break;
      case 'hold_out':
        _currentPhase = 'inhale';
        _cycleCount++;
        _controller.duration = Duration(seconds: _pattern['inhale']!.toInt());
        _controller.forward();
        break;
    }
  }

  void _updateBreathPhase() {
    String instruction = '';

    switch (_currentPhase) {
      case 'inhale':
        instruction = 'INHALE deeply through your nose';
        break;
      case 'hold_in':
        instruction = 'HOLD your breath';
        break;
      case 'exhale':
        instruction = 'EXHALE slowly through your mouth';
        break;
      case 'hold_out':
        instruction = 'HOLD (lungs empty)';
        break;
    }

    setState(() {
      _breathPhase = instruction;
    });
  }

  String _getPhaseTime() {
    double total = _pattern[_currentPhase]!;
    int remaining = total.toInt() - _secondsInPhase;
    return '${remaining}s';
  }

  @override
  void dispose() {
    _controller.dispose();
    _breathTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPattern = _patterns[_selectedPatternIndex];

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              currentPattern['color'].withOpacity(0.1),
              currentPattern['color'].withOpacity(0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Header
                  Row(
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.grey.shade700),
                        onPressed: () => Navigator.pop(context),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Breathing Exercises',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 30),

                  // Breathing visualization
                  Container(
                    padding: EdgeInsets.all(20),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return Stack(
                          alignment: Alignment.center,
                          children: [
                            if (_isBreathing && _currentPhase == 'inhale')
                              Container(
                                width: 300 * _animation.value,
                                height: 300 * _animation.value,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: currentPattern['color'].withOpacity(0.1),
                                ),
                              ),

                            Container(
                              width: 250,
                              height: 250,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    currentPattern['color'],
                                    currentPattern['color'].withOpacity(0.7),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: currentPattern['color'].withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      _breathPhase.split(' ')[0],
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      _getPhaseTime(),
                                      style: TextStyle(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w300,
                                        color: Colors.white,
                                        fontFamily: 'Monospace',
                                      ),
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      'Cycle: $_cycleCount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.white.withOpacity(0.9),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 30),

                  // Pattern selector
                  Container(
                    padding: EdgeInsets.all(16),
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
                          'Breathing Pattern',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 10),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _patterns.asMap().entries.map((entry) {
                              int index = entry.key;
                              Map<String, dynamic> pattern = entry.value;
                              bool isSelected = index == _selectedPatternIndex;

                              return GestureDetector(
                                onTap: () {
                                  if (!_isBreathing) {
                                    setState(() {
                                      _selectedPatternIndex = index;
                                    });
                                    _loadPattern(pattern);
                                  }
                                },
                                child: Container(
                                  margin: EdgeInsets.only(right: 12),
                                  padding: EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: isSelected ? pattern['color'].withOpacity(0.1) : Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isSelected ? pattern['color'] : Colors.transparent,
                                      width: 2,
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pattern['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: pattern['color'],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        pattern['description'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildPatternTime('In', pattern['inhale'], pattern['color']),
                                          SizedBox(width: 8),
                                          Text('→', style: TextStyle(color: Colors.grey)),
                                          SizedBox(width: 8),
                                          _buildPatternTime('Hold', pattern['hold_in'], pattern['color']),
                                          SizedBox(width: 8),
                                          Text('→', style: TextStyle(color: Colors.grey)),
                                          SizedBox(width: 8),
                                          _buildPatternTime('Out', pattern['exhale'], pattern['color']),
                                          if (pattern['hold_out'] > 0) ...[
                                            SizedBox(width: 8),
                                            Text('→', style: TextStyle(color: Colors.grey)),
                                            SizedBox(width: 8),
                                            _buildPatternTime('Hold', pattern['hold_out'], pattern['color']),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Instructions
                  Container(
                    padding: EdgeInsets.all(16),
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
                          children: [
                            Icon(Icons.help_outline, color: currentPattern['color'], size: 20),
                            SizedBox(width: 8),
                            Text(
                              'How to Practice',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          '• Sit comfortably with straight back\n'
                              '• Place one hand on your chest, other on belly\n'
                              '• Follow the animation and instructions\n'
                              '• Practice for 5-10 cycles daily\n'
                              '• Can be done anywhere, anytime',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // ✅ UPDATED: Streak Stats Section
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.local_fire_department, color: Colors.orange.shade700),
                            SizedBox(width: 8),
                            Text(
                              'Your Progress',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade800,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildBreathingStat(
                              Icons.local_fire_department,
                              'Current Streak',
                              '${StreakService().getBreathingStreak()}',
                              'days',
                              Colors.orange,
                            ),
                            _buildBreathingStat(
                              Icons.star,
                              'Longest',
                              '${StreakService().getLongestBreathingStreak()}',
                              'days',
                              Colors.amber,
                            ),
                            _buildBreathingStat(
                              Icons.air,
                              'Total',
                              '${StreakService().getTotalBreathingSessions()}',
                              'sessions',
                              Colors.blue,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 30),

                  // Control buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isBreathing)
                        ElevatedButton(
                          onPressed: _stopBreathing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade400,
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.stop, size: 20),
                              SizedBox(width: 8),
                              Text('STOP', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      else
                        ElevatedButton(
                          onPressed: _startBreathing,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentPattern['color'],
                            padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow, size: 20),
                              SizedBox(width: 8),
                              Text('START BREATHING', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                    ],
                  ),

                  SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPatternTime(String label, int seconds, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '$label: ${seconds}s',
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ✅ New helper method for streak stats
  Widget _buildBreathingStat(IconData icon, String label, String value, String unit, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            SizedBox(width: 2),
            Text(
              unit,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}