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
  }) async {
    final prefs = await _preferences;
    await prefs.setString(AppConstants.tokenKey, token);
    await prefs.setString(AppConstants.userIdKey, userId);
    await prefs.setString(AppConstants.usernameKey, username);
  }

  Future<String?> getUserId() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.userIdKey);
  }

  Future<String?> getUsername() async {
    final prefs = await _preferences;
    return prefs.getString(AppConstants.usernameKey);
  }

  Future<void> clearAuth() async {
    final prefs = await _preferences;
    await prefs.remove(AppConstants.tokenKey);
    await prefs.remove(AppConstants.userIdKey);
    await prefs.remove(AppConstants.usernameKey);
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null;
  }
}
