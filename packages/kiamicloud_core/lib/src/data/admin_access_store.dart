import 'package:shared_preferences/shared_preferences.dart';

/// Mantém acesso às ferramentas de admin na UI mesmo se a API actual estiver offline.
abstract final class AdminAccessStore {
  static const _prefKey = 'admin_ui_eligible_v1';

  static Future<bool> isEligible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  static Future<void> setEligible(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value) {
      await prefs.setBool(_prefKey, true);
    } else {
      await prefs.remove(_prefKey);
    }
  }

  static Future<void> clear() => setEligible(false);
}
