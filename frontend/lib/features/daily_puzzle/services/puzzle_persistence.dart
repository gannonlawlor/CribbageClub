import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'puzzle_generator.dart';

class PuzzleProgress {
  final List<int?> ranks;
  final List<double?> scores;
  final int nextIndex;

  const PuzzleProgress({
    required this.ranks,
    required this.scores,
    required this.nextIndex,
  });
}

class PuzzlePersistence {
  static const _keyLastDate = 'daily_puzzle_last_date';
  static const _keyStreak = 'daily_puzzle_streak';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Save a single puzzle result within the daily set.
  Future<void> savePuzzleResult(
    DateTime date,
    int index,
    int rank,
    double score,
  ) async {
    final prefs = await _preferences;
    final dateStr = _formatDate(date);
    final n = PuzzleGenerator.puzzlesPerDay;

    // Load existing or create new lists
    final ranks = _loadIntList(prefs, _ranksKey(dateStr), n);
    final scores = _loadDoubleList(prefs, _scoresKey(dateStr), n);

    ranks[index] = rank;
    scores[index] = score;

    await prefs.setString(_ranksKey(dateStr), jsonEncode(ranks));
    await prefs.setString(_scoresKey(dateStr), jsonEncode(scores));
  }

  /// Finalize the day — update streak based on whether all puzzles were rank 1.
  Future<void> finalizeDayResults(DateTime date) async {
    final prefs = await _preferences;
    final dateStr = _formatDate(date);
    final n = PuzzleGenerator.puzzlesPerDay;
    final ranks = _loadIntList(prefs, _ranksKey(dateStr), n);

    final allOptimal = ranks.every((r) => r == 1);
    final lastDateStr = prefs.getString(_keyLastDate);
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;

    int newStreak;
    if (allOptimal && lastDateStr != null) {
      final lastDate = _parseDate(lastDateStr);
      final yesterday = DateTime(date.year, date.month, date.day - 1);
      if (lastDate.year == yesterday.year &&
          lastDate.month == yesterday.month &&
          lastDate.day == yesterday.day) {
        newStreak = currentStreak + 1;
      } else {
        newStreak = 1;
      }
    } else if (allOptimal) {
      newStreak = 1;
    } else {
      newStreak = 0;
    }

    await prefs.setString(_keyLastDate, dateStr);
    await prefs.setInt(_keyStreak, newStreak);
  }

  /// Load partial progress for a given date. Returns ranks, scores, and the
  /// index of the next unsolved puzzle.
  Future<PuzzleProgress> getProgress(DateTime date) async {
    final prefs = await _preferences;
    final dateStr = _formatDate(date);
    final n = PuzzleGenerator.puzzlesPerDay;

    final ranks = _loadNullableIntList(prefs, _ranksKey(dateStr), n);
    final scores = _loadNullableDoubleList(prefs, _scoresKey(dateStr), n);

    var nextIndex = n; // all complete
    for (var i = 0; i < n; i++) {
      if (ranks[i] == null) {
        nextIndex = i;
        break;
      }
    }

    return PuzzleProgress(ranks: ranks, scores: scores, nextIndex: nextIndex);
  }

  Future<int> getStreak() async {
    final prefs = await _preferences;
    return prefs.getInt(_keyStreak) ?? 0;
  }

  Future<bool> hasCompletedToday() async {
    final progress = await getProgress(DateTime.now());
    return progress.nextIndex >= PuzzleGenerator.puzzlesPerDay;
  }

  // --- Key helpers ---

  String _ranksKey(String dateStr) => 'daily_puzzle_ranks_$dateStr';
  String _scoresKey(String dateStr) => 'daily_puzzle_scores_$dateStr';

  // --- List helpers ---

  List<int?> _loadNullableIntList(
    SharedPreferences prefs,
    String key,
    int length,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return List.filled(length, null);
    final list = (jsonDecode(raw) as List).cast<int?>();
    // Pad if stored list is shorter (shouldn't happen, but defensive)
    while (list.length < length) {
      list.add(null);
    }
    return list;
  }

  List<double?> _loadNullableDoubleList(
    SharedPreferences prefs,
    String key,
    int length,
  ) {
    final raw = prefs.getString(key);
    if (raw == null) return List.filled(length, null);
    final list = (jsonDecode(raw) as List).map((e) {
      if (e == null) return null;
      return (e as num).toDouble();
    }).toList();
    while (list.length < length) {
      list.add(null);
    }
    return list;
  }

  List<int?> _loadIntList(SharedPreferences prefs, String key, int length) {
    return _loadNullableIntList(prefs, key, length);
  }

  List<double?> _loadDoubleList(
    SharedPreferences prefs,
    String key,
    int length,
  ) {
    return _loadNullableDoubleList(prefs, key, length);
  }

  // --- Date helpers ---

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
