import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StreakService {
  // Singleton pattern
  static final StreakService _instance = StreakService._internal();
  factory StreakService() => _instance;
  StreakService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Streak data storage (will be replaced with Hive later)
  Map<String, dynamic> _streakData = {
    'meditation': {
      'lastDate': null,
      'currentStreak': 0,
      'longestStreak': 0,
      'totalSessions': 0,
    },
    'breathing': {
      'lastDate': null,
      'currentStreak': 0,
      'longestStreak': 0,
      'totalSessions': 0,
    },
    'journal': {
      'lastDate': null,
      'currentStreak': 0,
      'longestStreak': 0,
      'totalEntries': 0,
    },
    'mood': {
      'lastDate': null,
      'currentStreak': 0,
      'longestStreak': 0,
      'totalEntries': 0,
    },
    'overall': {
      'lastDate': null,
      'currentStreak': 0,
      'longestStreak': 0,
    },
  };

  // Load streaks from Firestore
  Future<void> loadStreaks() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        if (data.containsKey('streaks')) {
          Map<String, dynamic> streaks = data['streaks'] as Map<String, dynamic>;
          
          streaks.forEach((key, value) {
            if (_streakData.containsKey(key)) {
              _streakData[key]['currentStreak'] = value['currentStreak'] ?? 0;
              _streakData[key]['longestStreak'] = value['longestStreak'] ?? 0;
              _streakData[key]['totalSessions'] = value['totalSessions'] ?? 0;
              _streakData[key]['totalEntries'] = value['totalEntries'] ?? 0;
              
              if (value['lastDate'] != null) {
                if (value['lastDate'] is Timestamp) {
                  _streakData[key]['lastDate'] = (value['lastDate'] as Timestamp).toDate();
                } else if (value['lastDate'] is String) {
                  _streakData[key]['lastDate'] = DateTime.parse(value['lastDate']);
                }
              }
            }
          });
          print('🔥 StreakService: Loaded streaks for ${user.uid}');
        }
      }
    } catch (e) {
      print('❌ StreakService error loading: $e');
    }
  }

  // Save streaks to Firestore
  Future<void> saveStreaks() async {
    User? user = _auth.currentUser;
    if (user == null) return;

    try {
      // Prepare data for Firestore (convert DateTime to Timestamp)
      Map<String, dynamic> streaksToSave = {};
      _streakData.forEach((key, value) {
        streaksToSave[key] = Map<String, dynamic>.from(value);
        if (value['lastDate'] != null) {
          streaksToSave[key]['lastDate'] = Timestamp.fromDate(value['lastDate'] as DateTime);
        }
      });

      await _firestore.collection('users').doc(user.uid).set({
        'streaks': streaksToSave,
      }, SetOptions(merge: true));
      print('🔥 StreakService: Saved streaks for ${user.uid}');
    } catch (e) {
      print('❌ StreakService error saving: $e');
    }
  }

  // Update streak when user completes an activity
  void updateStreak(String activityType) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final lastDate = _streakData[activityType]['lastDate'];

    // Update total sessions/entries
    if (activityType == 'meditation' || activityType == 'breathing') {
      _streakData[activityType]['totalSessions'] += 1;
    } else if (activityType == 'journal' || activityType == 'mood') {
      _streakData[activityType]['totalEntries'] += 1;
    }

    if (lastDate == null) {
      // First time ever
      _streakData[activityType]['currentStreak'] = 1;
      _streakData[activityType]['longestStreak'] = 1;
    } else {
      final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
      final difference = today.difference(last).inDays;

      if (difference == 1) {
        // Consecutive day
        _streakData[activityType]['currentStreak'] += 1;

        // Update longest streak if needed
        if (_streakData[activityType]['currentStreak'] >
            _streakData[activityType]['longestStreak']) {
          _streakData[activityType]['longestStreak'] =
          _streakData[activityType]['currentStreak'];
        }
      } else if (difference > 1) {
        // Streak broken
        _streakData[activityType]['currentStreak'] = 1;
      }
      // difference == 0 means already logged today - do nothing
    }

    _streakData[activityType]['lastDate'] = today;

    // Update overall streak
    _updateOverallStreak(today);
    
    // Save to Firestore asynchronously
    saveStreaks();
  }

  void _updateOverallStreak(DateTime today) {
    // Check if user did ANY activity today
    bool didAnyActivity = false;

    ['meditation', 'breathing', 'journal', 'mood'].forEach((type) {
      final lastDate = _streakData[type]['lastDate'];
      if (lastDate != null) {
        final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
        if (last == today) {
          didAnyActivity = true;
        }
      }
    });

    final overallLast = _streakData['overall']['lastDate'];

    if (overallLast == null) {
      if (didAnyActivity) {
        _streakData['overall']['currentStreak'] = 1;
        _streakData['overall']['longestStreak'] = 1;
      }
    } else {
      final last = DateTime(overallLast.year, overallLast.month, overallLast.day);
      final difference = today.difference(last).inDays;

      if (difference == 1 && didAnyActivity) {
        _streakData['overall']['currentStreak'] += 1;

        if (_streakData['overall']['currentStreak'] >
            _streakData['overall']['longestStreak']) {
          _streakData['overall']['longestStreak'] =
          _streakData['overall']['currentStreak'];
        }
      } else if (difference > 1) {
        // Only reset if we missed a day
        _streakData['overall']['currentStreak'] = didAnyActivity ? 1 : 0;
      }
    }

    if (didAnyActivity) {
      _streakData['overall']['lastDate'] = today;
    }
  }

  // Getters for streak data
  int getMeditationStreak() => _streakData['meditation']['currentStreak'];
  int getBreathingStreak() => _streakData['breathing']['currentStreak'];
  int getJournalStreak() => _streakData['journal']['currentStreak'];
  int getMoodStreak() => _streakData['mood']['currentStreak'];
  int getOverallStreak() => _streakData['overall']['currentStreak'];

  int getLongestMeditationStreak() => _streakData['meditation']['longestStreak'];
  int getLongestBreathingStreak() => _streakData['breathing']['longestStreak'];
  int getLongestJournalStreak() => _streakData['journal']['longestStreak'];
  int getLongestMoodStreak() => _streakData['mood']['longestStreak'];
  int getLongestOverallStreak() => _streakData['overall']['longestStreak'];

  int getTotalMeditationSessions() => _streakData['meditation']['totalSessions'];
  int getTotalBreathingSessions() => _streakData['breathing']['totalSessions'];
  int getTotalJournalEntries() => _streakData['journal']['totalEntries'];
  int getTotalMoodEntries() => _streakData['mood']['totalEntries'];

  // Check if activity done today
  bool isActivityDoneToday(String activityType) {
    final lastDate = _streakData[activityType]['lastDate'];
    if (lastDate == null) return false;

    final today = DateTime.now();
    final last = DateTime(lastDate.year, lastDate.month, lastDate.day);
    final todayDate = DateTime(today.year, today.month, today.day);

    return last == todayDate;
  }

  // Get formatted last activity date
  String getLastActivityDate(String activityType) {
    final lastDate = _streakData[activityType]['lastDate'];
    if (lastDate == null) return 'Never';

    return DateFormat('MMM dd, yyyy').format(lastDate);
  }

  // Get motivational message based on streak
  String getMotivationalMessage(int streak) {
    if (streak == 0) return "Start your journey today! 🌱";
    if (streak == 1) return "Great start! Come back tomorrow! 🌟";
    if (streak <= 3) return "Building a habit! Keep going! 💪";
    if (streak <= 7) return "One week strong! Amazing! 🔥";
    if (streak <= 14) return "Two weeks! You're on fire! 🚀";
    if (streak <= 30) return "One month! Incredible dedication! 🌟";
    if (streak <= 60) return "Two months! You're a champion! 🏆";
    if (streak <= 90) return "Three months! Unstoppable! 💫";
    return "Legendary streak! You're inspiring! 👑";
  }

  // Get streak emoji based on length
  String getStreakEmoji(int streak) {
    if (streak == 0) return "🌱";
    if (streak < 3) return "🔥";
    if (streak < 7) return "⚡";
    if (streak < 14) return "🚀";
    if (streak < 30) return "💫";
    if (streak < 60) return "🏆";
    return "👑";
  }
}