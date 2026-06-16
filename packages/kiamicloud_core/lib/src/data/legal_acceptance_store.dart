import 'package:shared_preferences/shared_preferences.dart';

/// Registo de aceitação dos documentos legais (por utilizador).
abstract final class LegalAcceptanceStore {
  static String _key(String uid) => 'legal_accepted_v1_$uid';

  static Future<bool> hasAccepted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key(uid)) ?? false;
  }

  static Future<void> markAccepted(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key(uid), true);
  }
}
