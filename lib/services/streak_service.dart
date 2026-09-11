import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/streak_model.dart';
import 'firebase_service.dart';

class StreakService {
  final FirebaseFirestore _firestore = FirebaseService().firestore;

  // Get streak document for user
  Future<StreakModel?> getUserStreak(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('streaks')
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        return null;
      }

      return StreakModel.fromMap(
        snapshot.docs.first.id,
        snapshot.docs.first.data(),
      );
    } catch (e) {
      throw Exception('Failed to get streak: $e');
    }
  }

  // Stream of user streak
  Stream<StreakModel?> getUserStreakStream(String userId) {
    return _firestore
        .collection('streaks')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return StreakModel.fromMap(
            snapshot.docs.first.id,
            snapshot.docs.first.data(),
          );
        });
  }

  // Create initial streak for a user
  Future<StreakModel> createStreak(String userId) async {
    try {
      final streak = StreakModel.initial(userId);
      final docRef = await _firestore.collection('streaks').add(streak.toMap());

      return StreakModel(
        id: docRef.id,
        userId: streak.userId,
        currentStreak: streak.currentStreak,
        longestStreak: streak.longestStreak,
        lastCompletedDate: streak.lastCompletedDate,
        totalDaysCompleted: streak.totalDaysCompleted,
        streakStartDate: streak.streakStartDate,
        updatedAt: streak.updatedAt,
      );
    } catch (e) {
      throw Exception('Failed to create streak: $e');
    }
  }

  // Update streak
  Future<void> updateStreak(StreakModel streak) async {
    try {
      await _firestore
          .collection('streaks')
          .doc(streak.id)
          .update(streak.toMap());
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  // Calculate and update streak based on adherence logs
  Future<StreakModel> calculateStreak({
    required String userId,
    required List<DateTime> completedDates,
    required int totalAdherenceDays,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Get existing streak
    StreakModel? existingStreak = await getUserStreak(userId);
    existingStreak ??= await createStreak(userId);

    // Sort completed dates in descending order
    completedDates.sort((a, b) => b.compareTo(a));

    // Calculate current streak
    int currentStreak = 0;
    DateTime? lastDate;

    for (var date in completedDates) {
      final normalizedDate = DateTime(date.year, date.month, date.day);

      if (lastDate == null) {
        final diff = today.difference(normalizedDate).inDays;
        // Accept today or yesterday as streak start
        if (diff <= 1) {
          currentStreak = 1;
          lastDate = normalizedDate;
        } else {
          break;
        }
      } else {
        final diff = lastDate.difference(normalizedDate).inDays;
        if (diff == 1) {
          currentStreak++;
          lastDate = normalizedDate;
        } else if (diff == 0) {
          continue;
        } else {
          break;
        }
      }
    }

    // Update longest streak if needed
    final newLongestStreak = currentStreak > existingStreak.longestStreak
        ? currentStreak
        : existingStreak.longestStreak;

    // Update streak start date
    final streakStartDate = currentStreak > 0
        ? today.subtract(Duration(days: currentStreak - 1))
        : null;

    final updatedStreak = existingStreak.copyWith(
      currentStreak: currentStreak,
      longestStreak: newLongestStreak,
      lastCompletedDate: today,
      totalDaysCompleted: totalAdherenceDays,
      streakStartDate: streakStartDate,
      updatedAt: DateTime.now(),
    );

    await updateStreak(updatedStreak);
    return updatedStreak;
  }

  // Check if streak was broken (missed yesterday)
  Future<bool> isStreakBroken(String userId) async {
    final streak = await getUserStreak(userId);
    if (streak == null || streak.currentStreak == 0) return false;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final lastCompleted = DateTime(
      streak.lastCompletedDate.year,
      streak.lastCompletedDate.month,
      streak.lastCompletedDate.day,
    );

    final diff = today.difference(lastCompleted).inDays;
    return diff > 1;
  }

  // Reset streak
  Future<void> resetStreak(String userId) async {
    final streak = await getUserStreak(userId);
    if (streak == null) return;

    final updatedStreak = streak.copyWith(
      currentStreak: 0,
      streakStartDate: null,
      updatedAt: DateTime.now(),
    );

    await updateStreak(updatedStreak);
  }

  // Get weekly streak data (for chart)
  Future<List<bool>> getWeeklyStreakData(String userId) async {
    final now = DateTime.now();
    final List<bool> weeklyData = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection('adherence_logs')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: 'taken')
          .where('scheduledTime', isGreaterThanOrEqualTo: startOfDay)
          .where('scheduledTime', isLessThan: endOfDay)
          .limit(1)
          .get();

      weeklyData.add(snapshot.docs.isNotEmpty);
    }

    return weeklyData;
  }
}
