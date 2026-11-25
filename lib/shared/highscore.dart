import 'package:shared_preferences/shared_preferences.dart';

class StreakHighScore {
  static const _highScoreKey = 'high_score';

  static Future<void> saveHighScore(int newScore) async {
    final prefs = await SharedPreferences.getInstance();
    final currentHigh = prefs.getInt(_highScoreKey) ?? 0;

    if(newScore > currentHigh){
      await prefs.setInt(_highScoreKey, newScore);
    }
  }

  static Future<int> getHighScore() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_highScoreKey) ?? 0;
  }
}