import 'package:flutter/material.dart';
import '../models/streak_model.dart';

class StreakCard extends StatelessWidget {
  final StreakModel? streak;
  final List<bool> weeklyData;

  const StreakCard({super.key, this.streak, required this.weeklyData});

  @override
  Widget build(BuildContext context) {
    final currentStreak = streak?.currentStreak ?? 0;
    final longestStreak = streak?.longestStreak ?? 0;
    final streakEmoji = streak?.streakEmoji ?? '💤';
    final streakMessage = streak?.streakMessage ?? 'Start today!';

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getStreakColor(currentStreak),
            _getStreakColor(currentStreak).withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getStreakColor(currentStreak).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🔥 Your Streak',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Best: $longestStreak',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Main streak display
          Row(
            children: [
              Text(streakEmoji, style: const TextStyle(fontSize: 60)),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currentStreak',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Text(
                          'days',
                          style: TextStyle(color: Colors.white70, fontSize: 18),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    streakMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Weekly progress
          const Text(
            'Last 7 Days',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (index) {
              final dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
              final now = DateTime.now();
              final date = now.subtract(Duration(days: 6 - index));
              final dayLabel = dayLabels[date.weekday % 7];
              final isCompleted =
                  index < weeklyData.length && weeklyData[index];
              final isToday = index == 6;

              return Column(
                children: [
                  Text(
                    dayLabel,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 10,
                      fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: isCompleted
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: isToday
                          ? Border.all(color: Colors.white, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: isCompleted
                          ? Icon(
                              Icons.check,
                              color: _getStreakColor(currentStreak),
                              size: 18,
                            )
                          : Text(
                              '${date.day}',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getStreakColor(int streakCount) {
    if (streakCount >= 100) return const Color(0xFFD4AF37); // Gold
    if (streakCount >= 30) return const Color(0xFF9C27B0); // Purple
    if (streakCount >= 14) return const Color(0xFF3F51B5); // Indigo
    if (streakCount >= 7) return const Color(0xFF2196F3); // Blue
    if (streakCount >= 3) return const Color(0xFFFF9800); // Orange
    if (streakCount >= 1) return const Color(0xFF4CAF50); // Green
    return const Color(0xFF9E9E9E); // Grey
  }
}
