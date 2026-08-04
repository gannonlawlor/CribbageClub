import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/rest_client.dart';
import '../models/game_analysis.dart';

final analysisCacheServiceProvider = Provider<AnalysisCacheService>((ref) {
  return AnalysisCacheService();
});

class AnalysisCacheService {
  static const _keyPrefix = 'analysis_';
  static const _pendingKey = 'pending_analysis_uploads';

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<GameAnalysis?> getCachedAnalysis(String gameId) async {
    final prefs = await _preferences;
    final json = prefs.getString('$_keyPrefix$gameId');
    if (json == null) return null;
    return GameAnalysis.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> cacheAnalysis(String gameId, GameAnalysis analysis) async {
    final prefs = await _preferences;
    await prefs.setString('$_keyPrefix$gameId', jsonEncode(analysis.toJson()));
  }

  Future<List<String>> getPendingUploads() async {
    final prefs = await _preferences;
    final json = prefs.getString(_pendingKey);
    if (json == null) return [];
    return (jsonDecode(json) as List).cast<String>();
  }

  Future<void> addPendingUpload(String gameId) async {
    final pending = await getPendingUploads();
    if (!pending.contains(gameId)) {
      pending.add(gameId);
      final prefs = await _preferences;
      await prefs.setString(_pendingKey, jsonEncode(pending));
    }
  }

  Future<void> removePendingUpload(String gameId) async {
    final pending = await getPendingUploads();
    pending.remove(gameId);
    final prefs = await _preferences;
    await prefs.setString(_pendingKey, jsonEncode(pending));
  }

  Future<void> uploadPendingAnalyses(RestClient restClient) async {
    final pending = await getPendingUploads();
    if (pending.isEmpty) return;

    debugPrint('[AnalysisCache] Uploading ${pending.length} pending analyses');
    for (final gameId in List<String>.of(pending)) {
      final analysis = await getCachedAnalysis(gameId);
      if (analysis == null) {
        await removePendingUpload(gameId);
        continue;
      }
      try {
        await restClient.saveGameAnalysis(gameId, analysis);
        await removePendingUpload(gameId);
        debugPrint('[AnalysisCache] Uploaded analysis for $gameId');
      } catch (e) {
        debugPrint('[AnalysisCache] Failed to upload analysis for $gameId: $e');
      }
    }
  }
}
