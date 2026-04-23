import 'package:shared_preferences/shared_preferences.dart';

class AuthLocalStorage {
  static const String _loggedInKey = 'is_logged_in';
  static const String _firstLaunchKey = 'first_launch_done';
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'language';
  static const String _lastActiveMsKey = 'last_active_ms';

  static const Duration inactivityLogoutDuration = Duration(days: 30);

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loggedInKey) ?? false;
  }

  static Future<void> saveLoginStatus({required bool isLoggedIn}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loggedInKey, isLoggedIn);
    await prefs.setInt(_lastActiveMsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<void> clearLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loggedInKey);
    await prefs.remove(_lastActiveMsKey);
  }

  static Future<void> markFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_firstLaunchKey, true);
  }

  static Future<bool> isFirstLaunchDone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_firstLaunchKey) ?? false;
  }

  static Future<void> saveDarkMode(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_darkModeKey, isDarkMode);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_darkModeKey) ?? true;
  }

  static Future<void> saveLanguage(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  static Future<String> getLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey) ?? 'vi';
  }

  static Future<void> updateLastActive() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastActiveMsKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> shouldAutoLogout() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveMs = prefs.getInt(_lastActiveMsKey);
    if (lastActiveMs == null) {
      return false;
    }
    final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMs);
    return DateTime.now().difference(lastActive) >= inactivityLogoutDuration;
  }
}
