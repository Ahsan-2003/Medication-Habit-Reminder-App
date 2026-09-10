import 'package:cloud_firestore/cloud_firestore.dart';

class StreakModel {
  final String id;
  final String userId;
  final int currentStreak;
  final int longestStreak;
  final DateTime lastCompletedDate;
  final int totalDaysCompleted;
  final DateTime? streakStartDate;
  final DateTime updatedAt;

  StreakModel({
    this.id = '',
    required this.userId,
    required this.currentStreak,
    required this.longestStreak,
    required this.lastCompletedDate,
    required this.totalDaysCompleted,
    this.streakStartDate,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastCompletedDate': lastCompletedDate,
      'totalDaysCompleted': totalDaysCompleted,
      'streakStartDate': streakStartDate,
      'updatedAt': updatedAt,
    };
  }

  factory StreakModel.fromMap(String id, Map<String, dynamic> map) {
    return StreakModel(
      id: id,
      userId: map['userId'] ?? '',
      currentStreak: map['currentStreak'] ?? 0,
      longestStreak: map['longestStreak'] ?? 0,
      lastCompletedDate: map['lastCompletedDate'] != null
          ? (map['lastCompletedDate'] as Timestamp).toDate()
          : DateTime.now(),
      totalDaysCompleted: map['totalDaysCompleted'] ?? 0,
      streakStartDate: map['streakStartDate'] != null
          ? (map['streakStartDate'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] != null
          ? (map['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  // Create initial streak
  factory StreakModel.initial(String userId) {
    return StreakModel(
      userId: userId,
      currentStreak: 0,
      longestStreak: 0,
      lastCompletedDate: DateTime.now(),
      totalDaysCompleted: 0,
      streakStartDate: null,
      updatedAt: DateTime.now(),
    );
  }

  StreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastCompletedDate,
    int? totalDaysCompleted,
    DateTime? streakStartDate,
    DateTime? updatedAt,
  }) {
    return StreakModel(
      id: id,
      userId: userId,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastCompletedDate: lastCompletedDate ?? this.lastCompletedDate,
      totalDaysCompleted: totalDaysCompleted ?? this.totalDaysCompleted,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Helper to get streak emoji based on count
  String get streakEmoji {
    if (currentStreak >= 100) return '🏆';
    if (currentStreak >= 30) return '🥇';
    if (currentStreak >= 14) return '🥈';
    if (currentStreak >= 7) return '🥉';
    if (currentStreak >= 3) return '🔥';
    if (currentStreak >= 1) return '✨';
    return '💤';
  }

  // Helper to get streak status message
  String get streakMessage {
    if (currentStreak >= 100) return 'Legendary!';
    if (currentStreak >= 30) return 'Amazing!';
    if (currentStreak >= 14) return 'Excellent!';
    if (currentStreak >= 7) return 'Great job!';
    if (currentStreak >= 3) return 'Keep it up!';
    if (currentStreak >= 1) return 'Good start!';
    return 'Start today!';
  }
}
