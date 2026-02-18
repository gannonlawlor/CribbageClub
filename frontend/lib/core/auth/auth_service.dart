import 'package:shared_preferences/shared_preferences.dart';
import '../../config/constants.dart';

class AuthService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<String?> getToken() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.tokenKey);
  }

  Future<void> saveAuth({
    required String token,
    required String userId,
    required String username,
    bool isGuest = false,
  }) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.usernameKey, username);
    await prefs.setBool(AppConstants.isGuestKey, isGuest);
  }

  Future<String?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.usernameKey);
  }

  Future<bool> getIsGuest() async {
    final prefs = await _preferences;
    return prefs.getBool(AppConstants.isGuestKey) ?? false;
  }

  Future<void> clearAuth() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
    await prefs.remove(AppConstants.isGuestKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
