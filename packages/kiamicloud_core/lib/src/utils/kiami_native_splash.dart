import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

/// Remove o splash nativo quando o ecrã Flutter assume.
void removeNativeSplash() {
  if (kIsWeb) return;
  FlutterNativeSplash.remove();
}
