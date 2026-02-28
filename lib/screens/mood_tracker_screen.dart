import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/streak_service.dart';
import '../models/user_activity.dart';

class MoodTrackerScreen extends StatefulWidget {
  const MoodTrackerScreen({super.key});

  @override
  State<MoodTrackerScreen> createState() => _MoodTrackerScreenState();
}

class _MoodTrackerScreenState extends State<MoodTrackerScreen> {
  final List<Map<String, dynamic>> _moodOptions = [
    {'emoji': '😊', 'label': 'Happy', 'color': Colors.amber, 'value': 5},
    {'emoji': '😌', 'label': 'Calm', 'color': Colors.blue, 'value': 4},
    {'emoji': '😐', 'label': 'Neutral', 'color': Colors.grey, 'value': 3},
    {'emoji': '😔', 'label': 'Sad', 'color': Colors.indigo, 'value': 2},
    {'emoji': '😡', 'label': 'Angry', 'color': Colors.red, 'value': 1},
    {'emoji': '😰', 'label': 'Anxious', 'color': Colors.orange, 'value': 2},
    {'emoji': '😴', 'label': 'Tired', 'color': Colors.purple, 'value': 2},
    {'emoji': '🤒', 'label': 'Sick', 'color': Colors.green, 'value': 1},
  ];

  List<Map<String, dynamic>> _moodHistory = [];
  DateTime _selectedDate = DateTime.now();
  Map<String, dynamic>? _selectedMood;
  double _averageMood = 0.0;
  String _mostCommonMood = '';
  String _bestDay = '';
  String _trend = '';

  // Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMoodHistory();
  }

  Future<void> _loadMoodHistory() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .orderBy('date', descending: true)
          .get();

      setState(() {
        _moodHistory.clear();
        for (var doc in snapshot.docs) {
          final data = doc.data();
          _moodHistory.add({
            'date': (data['date'] as Timestamp).toDate(),
            'mood': data['mood'],
            'moodLabel': data['moodLabel'],
            'moodColor': Color(data['moodColor'] as int),
            'moodValue': data['moodValue'],
            'note': data['note'],
          });
        }
        _calculateStatistics();
      });
    } catch (e) {
      _showSnackbar('Error loading mood history: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Removed _loadSampleData and _getSampleNote

  void _calculateStatistics() {
    if (_moodHistory.isEmpty) {
      setState(() {
        _averageMood = 0.0;
        _mostCommonMood = 'No data';
        _bestDay = 'No data';
        _trend = 'Start tracking your mood!';
      });
      return;
    }

    final int total = _moodHistory.fold<int>(0, (int sum, entry) => sum + (entry['moodValue'] as int));
    _averageMood = total / _moodHistory.length;

    final moodCounts = <String, int>{};
    for (var entry in _moodHistory) {
      final mood = entry['moodLabel'] as String;
      moodCounts[mood] = (moodCounts[mood] ?? 0) + 1;
    }

    _mostCommonMood = moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    final bestEntry = _moodHistory.reduce((a, b) => (a['moodValue'] as int) > (b['moodValue'] as int) ? a : b);
    _bestDay = DateFormat('MMM dd').format(bestEntry['date'] as DateTime);

    if (_moodHistory.length >= 14) {
      final recent = _moodHistory.take(7);
      final previous = _moodHistory.skip(7).take(7);

      final double recentAvg = recent.fold<int>(0, (int sum, e) => sum + (e['moodValue'] as int)) / 7;
      final double previousAvg = previous.fold<int>(0, (int sum, e) => sum + (e['moodValue'] as int)) / 7;

      if (recentAvg > previousAvg + 0.5) {
        _trend = 'Improving 📈';
      } else if (recentAvg < previousAvg - 0.5) {
        _trend = 'Declining 📉';
      } else {
        _trend = 'Stable ↔️';
      }
    } else {
      _trend = 'Need more data';
    }

    setState(() {});
  }

  Future<void> _logMood() async {
    if (_selectedMood == null) {
      _showSnackbar('Please select a mood first');
      return;
    }

    User? user = _auth.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      final moodData = {
        'date': Timestamp.fromDate(_selectedDate),
        'mood': _selectedMood!['emoji'],
        'moodLabel': _selectedMood!['label'],
        'moodColor': (_selectedMood!['color'] as Color).value,
        'moodValue': _selectedMood!['value'],
        'note': 'Logged mood',
      };

      // In a real app, you might want to check if an entry exists for this date first
      // For simplicity, we'll just add it.
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('moods')
          .add(moodData);

      _showSnackbar('Mood logged for ${DateFormat('MMM dd').format(_selectedDate)}');
      
      // Update streak
      StreakService().updateStreak('mood');
      
      // Reload history to refresh UI and stats
      await _loadMoodHistory();
      
      setState(() {
        _selectedMood = null;
      });
    } catch (e) {
      _showSnackbar('Error logging mood: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _deleteMood(DateTime date) {
    setState(() {
      _moodHistory.removeWhere((entry) {
        final entryDate = entry['date'] as DateTime;
        final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
        final targetDate = DateTime(date.year, date.month, date.day);
        return entryDay == targetDate;
      });
    });
    _calculateStatistics();
    _showSnackbar('Mood entry deleted');
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _showDatePicker() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(Duration(days: 365)),
      lastDate: DateTime.now().add(Duration(days: 1)),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
        _selectedMood = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Mood Tracker',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Statistics Cards
                Text(
                  'Your Mood Insights',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(child: _buildStatCard('Average Mood', '${_averageMood.toStringAsFixed(1)}/5', Icons.trending_up, Colors.blue)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Most Common', _mostCommonMood, Icons.emoji_emotions, Colors.green)),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildStatCard('Best Day', _bestDay, Icons.star, Colors.amber)),
                    SizedBox(width: 12),
                    Expanded(child: _buildStatCard('Trend', _trend, Icons.show_chart, Colors.purple)),
                  ],
                ),

                SizedBox(height: 24),

                // Log Mood Section
                Text(
                  'Log Your Mood',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                SizedBox(height: 16),

                // Date selector
                Row(
                  children: [
                    Text('Date: ', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: _showDatePicker,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today, size: 18, color: Colors.grey.shade600),
                            SizedBox(width: 8),
                            Text(DateFormat('MMM dd, yyyy').format(_selectedDate), style: TextStyle(color: Colors.grey.shade700)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 20),

                // Mood selector grid
                GridView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _moodOptions.length,
                  itemBuilder: (context, index) {
                    final mood = _moodOptions[index];
                    final isSelected = _selectedMood == mood;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedMood = mood),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? (mood['color'] as Color).withOpacity(0.2) : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isSelected ? mood['color'] as Color : Colors.transparent, width: 2),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(mood['emoji'] as String, style: TextStyle(fontSize: 28)),
                            SizedBox(height: 4),
                            Text(mood['label'] as String, style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: 24),

                // Log button
                ElevatedButton(
                  onPressed: _logMood,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedMood?['color'] ?? Colors.grey,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    minimumSize: Size(double.infinity, 0),
                  ),
                  child: Text(
                    _selectedMood == null ? 'SELECT A MOOD' : 'LOG ${(_selectedMood!['label'] as String).toUpperCase()} MOOD',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),

                SizedBox(height: 24),

                // Mood History
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mood History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey.shade800)),
                    Text('${_moodHistory.length} entries', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
                SizedBox(height: 16),

                if (_moodHistory.isEmpty)
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Column(
                      children: [
                        Icon(Icons.emoji_emotions_outlined, size: 60, color: Colors.grey.shade300),
                        SizedBox(height: 16),
                        Text('No mood entries yet', style: TextStyle(color: Colors.grey.shade600)),
                        SizedBox(height: 8),
                        Text('Log your first mood above!', style: TextStyle(color: Colors.grey.shade500)),
                      ],
                    ),
                  )
                else
                  Column(
                    children: _moodHistory.take(5).map((entry) => _buildMoodHistoryItem(entry)).toList(),
                  ),

                if (_moodHistory.length > 5)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Center(
                      child: Text('+ ${_moodHistory.length - 5} more entries', style: TextStyle(color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
            ],
          ),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildMoodHistoryItem(Map<String, dynamic> entry) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (entry['moodColor'] as Color).withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Center(child: Text(entry['mood'] as String, style: TextStyle(fontSize: 20))),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('MMM dd, yyyy').format(entry['date'] as DateTime),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                SizedBox(height: 4),
                Text(
                  entry['moodLabel'] as String,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, size: 18, color: Colors.grey.shade500),
            onPressed: () => _deleteMood(entry['date'] as DateTime),
          ),
        ],
      ),
    );
  }
}