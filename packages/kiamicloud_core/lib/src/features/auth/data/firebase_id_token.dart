import 'package:firebase_auth/firebase_auth.dart';

import '../../../firebase/kiami_firebase.dart';

/// Obtém o idToken Firebase para pedidos à API Workers (Bearer).
abstract final class FirebaseIdTokenService {
  static Future<String?> getIdToken({bool forceRefresh = false}) async {
    if (!KiamiFirebase.isConfigured) return null;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}
