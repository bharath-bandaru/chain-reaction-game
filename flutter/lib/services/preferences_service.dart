import 'package:shared_preferences/shared_preferences.dart';

/// Persistent user settings — the mobile equivalent of the web app's
/// `localStorage` keys (`showAnimation`, `showUndo`, `ai-level`).
class PreferencesService {
  PreferencesService(this._prefs);

  static const _kShowAnimation = 'showAnimation';
  static const _kShowUndo = 'showUndo';
  static const _kAiLevel = 'ai-level';

  final SharedPreferences _prefs;

  static Future<PreferencesService> load() async =>
      PreferencesService(await SharedPreferences.getInstance());

  bool get showAnimation => _prefs.getBool(_kShowAnimation) ?? false;
  set showAnimation(bool value) => _prefs.setBool(_kShowAnimation, value);

  bool get showUndo => _prefs.getBool(_kShowUndo) ?? true;
  set showUndo(bool value) => _prefs.setBool(_kShowUndo, value);

  String get aiLevel => _prefs.getString(_kAiLevel) ?? '2';
  set aiLevel(String value) => _prefs.setString(_kAiLevel, value);
}
