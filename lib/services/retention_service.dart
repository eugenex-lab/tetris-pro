import 'dart:math';
import 'notification_service.dart';
import '../data/retention_data.dart';

class RetentionService {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;
  RetentionService._internal();

  final NotificationService _notificationService = NotificationService();
  final Random _random = Random();

  /// Refreshes all retention notifications.
  /// This should be called on app start and when a game session ends.
  Future<void> refreshSchedules() async {
    // 1. Cancel all existing scheduled notifications to avoid duplicates/overlaps
    await _notificationService.cancelAllNotifications();

    final now = DateTime.now();

    // 2. Schedule Inactivity Ladder
    _scheduleInactivityLadder(now);

    // 3. Schedule Daily Rewards (Sliding Window: Next 30 days)
    _scheduleDailyRewards(now);
  }

  void _scheduleInactivityLadder(DateTime fromDate) {
    // Day 1 (24h)
    _scheduleRandomNotification(
      id: 101,
      title: 'Tetris Pro',
      messages: RetentionData.day1Messages,
      scheduledDate: fromDate.add(const Duration(days: 1)),
    );

    // Day 3 (72h)
    _scheduleRandomNotification(
      id: 103,
      title: 'Tetris Pro',
      messages: RetentionData.day3Messages,
      scheduledDate: fromDate.add(const Duration(days: 3)),
    );

    // Day 7 (1 Week)
    _scheduleRandomNotification(
      id: 107,
      title: '💰 50 Coins Waiting!',
      messages: RetentionData.day7Messages,
      scheduledDate: fromDate.add(const Duration(days: 7)),
      payload: 'REWARD:50',
    );

    // Day 30 (1 Month)
    _scheduleRandomNotification(
      id: 130,
      title: '🏆 Legendary Status',
      messages: RetentionData.day30Messages,
      scheduledDate: fromDate.add(const Duration(days: 30)),
    );
  }

  void _scheduleDailyRewards(DateTime fromDate) {
    // Schedule for the next 30 days to stay within OS limits (approx 64)
    for (int i = 1; i <= 30; i++) {
      // Use IDs in the 1000+ range for daily rewards
      final scheduledDate = fromDate.add(Duration(days: i));
      
      // We'll use day1Messages as base for general daily reminders if specific ones aren't defined
      // or we can just use a mix.
      _notificationService.scheduleNotification(
        id: 1000 + i,
        title: 'Daily Reward Available!',
        body: 'Don\'t forget to collect your daily coins!',
        scheduledDate: _atOptimalTime(scheduledDate),
        payload: 'REWARD:10',
      );
    }
  }

  void _scheduleRandomNotification({
    required int id,
    required String title,
    required List<String> messages,
    required DateTime scheduledDate,
    String? payload,
  }) {
    final body = messages[_random.nextInt(messages.length)];
    _notificationService.scheduleNotification(
      id: id,
      title: title,
      body: body,
      scheduledDate: _atOptimalTime(scheduledDate),
      payload: payload,
    );
  }

  /// Adjusts the scheduled date to an optimal time (e.g., 6:00 PM)
  /// to increase the likelihood of the user being free to play.
  DateTime _atOptimalTime(DateTime date) {
    return DateTime(date.year, date.month, date.day, 18, 0); // 6:00 PM
  }
}
