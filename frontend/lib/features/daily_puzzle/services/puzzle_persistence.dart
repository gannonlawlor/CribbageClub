import 'package:shared_preferences/shared_preferences.dart';

class PuzzlePersistence {
  static const _keyLastDate = 'daily_puzzle_last_date';
  static const _keyStreak = 'daily_puzzle_streak';
  static const _keyLastRank = 'daily_puzzle_last_rank';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> savePuzzleResult(DateTime date, int rank) async {
    final prefs = await _preferences;
    final dateStr = _formatDate(date);
    final lastDateStr = prefs.getString(_keyLastDate);
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;

    int newStreak;
    if (rank == 1 && lastDateStr != null) {
      final lastDate = _parseDate(lastDateStr);
      final yesterday = DateTime(date.year, date.month, date.day - 1);
      if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    } else if (rank == 1) {
      newStreak = 1;
    } else {
      newStreak = 0;
    }

    await prefs.setString(_keyLastDate, dateStr);
    await prefs.setInt(_keyStreak, newStreak);
    await prefs.setInt(_keyLastRank, rank);
  }

  Future<int> getStreak() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyStreak) ?? 0;
  }

  Future<String?> getLastPlayedDate() async {
    final prefs = await _preferences;
    return prefs.getString(_keyLastDate);
  }

  Future<bool> hasCompletedToday() async {
    final prefs = await _preferences;
    final lastDateStr = prefs.getString(_keyLastDate);
    if (lastDateStr == null) return false;
    final now = DateTime.now();
    return lastDateStr == _formatDate(now);
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '${date.month.toString().padLeft(2, '0')}'
      '${date.day.toString().padLeft(2, '0')}';

  DateTime _parseDate(String dateStr) {
    final year = int.parse(dateStr.substring(0, 4));
    final month = int.parse(dateStr.substring(4, 6));
    final day = int.parse(dateStr.substring(6, 8));
    return DateTime(year, month, day);
  }
}
