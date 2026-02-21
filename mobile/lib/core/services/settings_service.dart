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
    return prefs.getString(AppConstants.themeModeKey) ?? 'light';
  }

  Future<void> setThemeMode(String mode) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.themeModeKey, mode);
  }

  /// Load all settings at once (used during app startup).
  Future<({bool soundEnabled, bool hapticsEnabled, String themeMode})> loadAll() async {
    final prefs = await _preferences;
    return (
      soundEnabled: prefs.getBool(AppConstants.soundEnabledKey) ?? true,
      hapticsEnabled: prefs.getBool(AppConstants.hapticsEnabledKey) ?? true,
      themeMode: prefs.getString(AppConstants.themeModeKey) ?? 'light',
    );
  }
}
