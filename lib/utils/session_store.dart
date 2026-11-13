import 'package:shared_preferences/shared_preferences.dart';

/// Persists only the logged-in user id.
class SessionStore {
  static const _userIdKey = 'logged_in_user_id';

  Future<void> saveUserId(int userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, userId);
  }

  Future<int?> readUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_userIdKey);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = await prefs.remove(_userIdKey);
    if (!removed) throw StateError('Could not clear the saved session');
  }
}
