import 'package:shared_preferences/shared_preferences.dart';

class StreakService {
  static Future<int> updateStreak() async {
    final prefs = await SharedPreferences.getInstance();

    final lastDate = prefs.getString("last_open");
    final streak = prefs.getInt("streak") ?? 0;

    final today = DateTime.now().toIso8601String().substring(0, 10);

    if (lastDate == null) {
      await prefs.setString("last_open", today);
      await prefs.setInt("streak", 1);
      return 1;
    }

    final yesterday = DateTime.now()
        .subtract(const Duration(days: 1))
        .toIso8601String()
        .substring(0, 10);

    if (lastDate == today) {
      return streak;
    } else if (lastDate == yesterday) {
      final newStreak = streak + 1;
      await prefs.setInt("streak", newStreak);
      await prefs.setString("last_open", today);
      return newStreak;
    } else {
      await prefs.setInt("streak", 1);
      await prefs.setString("last_open", today);
      return 1;
    }
  }
}