import 'prefs_backend.dart';

class Prefs {
  static final PrefsBackend _b = PrefsBackend();
  static bool _inited = false;

  static Future<void> init() async {
    if (_inited) return;
    await _b.init();
    _inited = true;
  }

  static Future<String?> getString(String key) => _b.getString(key);
  static Future<void> setString(String key, String value) => _b.setString(key, value);
  static Future<void> remove(String key) => _b.remove(key);
}

