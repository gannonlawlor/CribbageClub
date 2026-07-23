import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class SettingsService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> getSoundEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.soundEnabledKey, enabled);
  }

  Future<bool> getHapticsEnabled() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.hapticsEnabledKey) ?? true;
  }

  Future<void> setHapticsEnabled(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.hapticsEnabledKey, enabled);
  }

  Future<String> getThemeMode() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.themeModeKey) ?? 'dark';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.themeModeKey, mode);
  }

  Future<bool> getPuzzlePickDiscards() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.puzzlePickDiscardsKey) ?? false;
  }

  Future<void> setPuzzlePickDiscards(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.puzzlePickDiscardsKey, enabled);
  }

  Future<bool> getAutoDeal() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.autoDealKey) ?? true;
  }

  Future<void> setAutoDeal(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoDealKey, enabled);
  }

  Future<bool> getAutoCut() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.autoCutKey) ?? true;
  }

  Future<void> setAutoCut(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoCutKey, enabled);
  }

  Future<bool> getAutoGo() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.autoGoKey) ?? true;
  }

  Future<void> setAutoGo(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoGoKey, enabled);
  }

  Future<bool> getAutoPlayAll() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.autoPlayAllKey) ?? false;
  }

  Future<void> setAutoPlayAll(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoPlayAllKey, enabled);
  }

  Future<bool> getAutoPlayPegging() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.autoPlayPeggingKey) ?? true;
  }

  Future<void> setAutoPlayPegging(bool enabled) async {
    final prefs = await _preferences;
    await prefs.setBool(AppConstants.autoPlayPeggingKey, enabled);
  }

  Future<double> getAnimationSpeed() async {
    final prefs = await _preferences;
    return prefs.getDouble(AppConstants.animationSpeedKey) ?? 1.0;
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
    );
  }
}
