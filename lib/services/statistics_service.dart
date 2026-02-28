// lib/services/statistics_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_activity.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get user's activities from Firestore
  Stream<List<UserActivity>> getUserActivities() {
    User? user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserActivity.fromMap(doc.data());
      }).toList();
    });
  }

  // Get today's total mindfulness minutes
  Future<int> getTodayMindfulnessMinutes() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;

    DateTime now = DateTime.now();
    DateTime startOfDay = DateTime(now.year, now.month, now.day);
    DateTime endOfDay = startOfDay.add(const Duration(days: 1));

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThan: Timestamp.fromDate(endOfDay))
        .where('activityType', whereIn: ['meditation', 'breathing'])
        .get();

    int totalMinutes = 0;
    for (var doc in snapshot.docs) {
      // ✅ FIX: Convert num to int
      var duration = doc['durationMinutes'];
      if (duration != null) {
        totalMinutes += (duration as num).toInt();
      }
    }
    return totalMinutes;
  }

  // Get total minutes meditated (all time)
  Future<int> getTotalMeditationMinutes() async {
    User? user = _auth.currentUser;
    if (user == null) return 0;

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .where('activityType', isEqualTo: 'meditation')
        .get();

    int totalMinutes = 0;
    for (var doc in snapshot.docs) {
      // ✅ FIX: Convert num to int
      var duration = doc['durationMinutes'];
      if (duration != null) {
        totalMinutes += (duration as num).toInt();
      }
    }
    return totalMinutes;
  }

  // Get weekly activity summary
  Future<Map<String, int>> getWeeklyActivitySummary() async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    DateTime now = DateTime.now();
    DateTime weekAgo = now.subtract(const Duration(days: 7));

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .get();

    Map<String, int> summary = {
      'meditation': 0,
      'breathing': 0,
      'journal': 0,
      'mood': 0,
    };

    for (var doc in snapshot.docs) {
      String type = doc['activityType'] as String? ?? '';
      if (summary.containsKey(type)) {
        summary[type] = summary[type]! + 1;
      }
    }

    return summary;
  }

  // Get mood distribution for last 30 days
  Future<Map<String, int>> getMoodDistribution() async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    DateTime now = DateTime.now();
    DateTime monthAgo = now.subtract(const Duration(days: 30));

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .where('activityType', isEqualTo: 'mood')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(monthAgo))
        .get();

    Map<String, int> moodCount = {
      'Happy': 0,
      'Calm': 0,
      'Neutral': 0,
      'Sad': 0,
    };

    for (var doc in snapshot.docs) {
      String mood = doc['mood'] as String? ?? 'Neutral';
      if (moodCount.containsKey(mood)) {
        moodCount[mood] = moodCount[mood]! + 1;
      }
    }

    return moodCount;
  }

  // Save an activity
  Future<void> saveActivity(UserActivity activity) async {
    User? user = _auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .add(activity.toMap());
  }

  // Get weekly progress for chart
  Future<Map<DateTime, int>> getWeeklyProgress() async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    DateTime now = DateTime.now();
    DateTime weekAgo = now.subtract(const Duration(days: 7));

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(weekAgo))
        .where('activityType', whereIn: ['meditation', 'breathing'])
        .get();

    Map<DateTime, int> dailyMinutes = {};

    for (var doc in snapshot.docs) {
      dynamic dateData = doc['date'];
      DateTime date;
      if (dateData is Timestamp) {
        date = dateData.toDate();
      } else {
        date = DateTime.parse(dateData as String);
      }
      DateTime day = DateTime(date.year, date.month, date.day);

      var duration = doc['durationMinutes'];
      int minutes = duration != null ? (duration as num).toInt() : 0;

      dailyMinutes[day] = (dailyMinutes[day] ?? 0) + minutes;
    }

    return dailyMinutes;
  }

  // Get activity count by type
  Future<Map<String, int>> getActivityCounts() async {
    User? user = _auth.currentUser;
    if (user == null) return {};

    QuerySnapshot snapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('activities')
        .get();

    Map<String, int> counts = {
      'meditation': 0,
      'breathing': 0,
      'journal': 0,
      'mood': 0,
    };

    for (var doc in snapshot.docs) {
      String type = doc['activityType'] as String? ?? '';
      if (counts.containsKey(type)) {
        counts[type] = counts[type]! + 1;
      }
    }

    return counts;
  }
}