import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class SettingsService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.soundEnabledKey, enabled);
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.hapticsEnabledKey, enabled);
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.themeModeKey, mode);
  }

  Future<void> setPuzzlePickDiscards(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.puzzlePickDiscardsKey, enabled);
  }

  Future<void> setAutoDeal(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoDealKey, enabled);
  }

  Future<void> setAutoCut(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoCutKey, enabled);
  }

  Future<void> setAutoGo(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoGoKey, enabled);
  }

  Future<void> setAutoPlayAll(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoPlayAllKey, enabled);
  }

  Future<void> setAutoPlayPegging(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoPlayPeggingKey, enabled);
  }

  Future<void> setOpponentHandDisplay(String key) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.opponentHandDisplayKey, key);
  }

  Future<void> setAnimationSpeed(double speed) async {
    final prefs = await _preferences;
    await prefs.setDouble(AppConstants.animationSpeedKey, speed);
  }

  /// Load all settings at once (used during app startup).
  Future<
    ({
      bool soundEnabled,
      bool hapticsEnabled,
      String themeMode,
      bool autoDeal,
      bool autoCut,
      bool autoGo,
      bool autoPlayAll,
      bool autoPlayPegging,
      double animationSpeed,
      bool puzzlePickDiscards,
      String? opponentHandDisplay,
    })
  >
  loadAll() async {
    final prefs = await _preferences;
    return (
      soundEnabled: prefs.getBool(AppConstants.soundEnabledKey) ?? true,
      hapticsEnabled: prefs.getBool(AppConstants.hapticsEnabledKey) ?? true,
      themeMode: prefs.getString(AppConstants.themeModeKey) ?? 'dark',
      autoDeal: prefs.getBool(AppConstants.autoDealKey) ?? true,
      autoCut: prefs.getBool(AppConstants.autoCutKey) ?? true,
      autoGo: prefs.getBool(AppConstants.autoGoKey) ?? true,
      autoPlayAll: prefs.getBool(AppConstants.autoPlayAllKey) ?? false,
      autoPlayPegging: prefs.getBool(AppConstants.autoPlayPeggingKey) ?? true,
      animationSpeed: prefs.getDouble(AppConstants.animationSpeedKey) ?? 1.0,
      puzzlePickDiscards:
          prefs.getBool(AppConstants.puzzlePickDiscardsKey) ?? false,
      opponentHandDisplay: prefs.getString(AppConstants.opponentHandDisplayKey),
    );
  }
}
