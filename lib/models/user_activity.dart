import 'package:cloud_firestore/cloud_firestore.dart';

// lib/models/user_activity.dart
class UserActivity {
  final DateTime date;
  final String activityType; // 'meditation', 'breathing', 'journal', 'mood'
  final int durationMinutes; // for meditation/breathing
  final String? mood; // for mood tracking
  final String? journalEntry; // for journal

  UserActivity({
    required this.date,
    required this.activityType,
    this.durationMinutes = 0,
    this.mood,
    this.journalEntry,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'activityType': activityType,
      'durationMinutes': durationMinutes,
      'mood': mood,
      'journalEntry': journalEntry,
    };
  }

  factory UserActivity.fromMap(Map<String, dynamic> map) {
    DateTime parsedDate;
    if (map['date'] is Timestamp) {
      parsedDate = (map['date'] as Timestamp).toDate();
    } else {
      parsedDate = DateTime.parse(map['date'] as String);
    }

    return UserActivity(
      date: parsedDate,
      activityType: map['activityType'] as String,
      // ✅ FIX: Convert num to int safely
      durationMinutes: (map['durationMinutes'] as num?)?.toInt() ?? 0,
      mood: map['mood'] as String?,
      journalEntry: map['journalEntry'] as String?,
    );
  }
}