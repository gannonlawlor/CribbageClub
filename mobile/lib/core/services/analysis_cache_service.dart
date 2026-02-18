import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_analysis.dart';

final analysisCacheServiceProvider = Provider<AnalysisCacheService>((ref) {
  return AnalysisCacheService();
});

class AnalysisCacheService {
  static const _keyPrefix = 'analysis_';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<GameAnalysis?> getCachedAnalysis(String gameId) async {
    final prefs = await _preferences;
    final json = prefs.getString('$_keyPrefix$gameId');
    if (json == null) return null;
    return GameAnalysis.fromJson(
      jsonDecode(json) as Map<String, dynamic>,
    );
  }

  Future<void> cacheAnalysis(String gameId, GameAnalysis analysis) async {
    final prefs = await _preferences;
    await prefs.setString(
      '$_keyPrefix$gameId',
      jsonEncode(analysis.toJson()),
    );
  }
}
